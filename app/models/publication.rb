# frozen_string_literal: true

class Publication < ApplicationRecord
  # MIXINS
  extend Ascii

  # CONSTANTS

  # ATTRIBUTES

  # MISCELLANEOUS

  # ASSOCIATIONS
  has_and_belongs_to_many :lifetraits
  has_and_belongs_to_many :parasitic_relationships

  has_many :publication_taxons
  has_many :taxa, through: :publication_taxons, source: :taxon

  # VALIDATIONS
  validates_uniqueness_of :doi,
                          if: :doi?

  validates_presence_of :title, :year, :authors

  # SCOPES
  scope :not_recent, lambda {
    where(<<-SQL)
      NOT EXISTS (SELECT 1
        FROM   publication_taxons
        WHERE  publication_taxons.publication_id = publications.id)
    SQL
  }

  scope :no_trait_info, lambda {
    where(<<-SQL)
      NOT EXISTS (SELECT 1
        FROM   lifetraits_publications
        WHERE  lifetraits_publications.publication_id = publications.id)
    SQL
  }

  scope :no_parasitic_relationship, lambda {
    where(<<-SQL)
      NOT EXISTS (SELECT 1
        FROM   parasitic_relationships
        WHERE  parasitic_relationships.publication_id = publications.id)
    SQL
  }

  scope :unlinked, lambda {
    not_recent.no_trait_info.no_parasitic_relationship
  }

  # CALLBACKS
  before_validation :resolve_doi_metadata, on: :create,
                                           if: :doi?

  # INSTANCE METHODS
  def fetch_url
    doi? ? "https://doi.org/#{doi}" : url
  end

  def fetch_relevant_species
    relevant_species = []
    relevant_ids = []

    taxa.each do |taxon| # recent publications
      relevant_species << taxon.scientific_name
      relevant_ids << taxon.id
    end

    lifetraits.each do |info_entry| # reference for life trait
      taxon = info_entry.taxon
      relevant_species << taxon.scientific_name
      relevant_ids << taxon.id
    end

    parasitic_relationships.each do |relationship| # reference for parasitic relationship
      relevant_species << relationship.parasite.scientific_name
      relevant_ids << relationship.parasite.id
    end

    relevant_species.zip(relevant_ids).uniq.sort_by { |x| x[0] }
  end

  def authors_to_string
    if authors.length > 2
      author_name = "#{JSON.parse(authors[0].gsub('=>', ':'))['family']} et al."
    elsif authors.length == 2
      author_name = "#{JSON.parse(authors[0].gsub('=>', ':'))['family']} & #{JSON.parse(authors[1].gsub('=>', ':'))['family']}"
    else
      author_name = (JSON.parse(authors[0].gsub('=>', ':'))['family']).to_s
    end
    author_name
  end

  # CLASS METHODS
  def self.fetch_publications_as_json(publications)
    publication_json = {}
    publication_counter = 1
    publications.each do |publication|
      url = if publication.doi?
              "https://doi.org/#{publication.doi}"
            elsif publication.url?
              publication.url
            end

      publication_json[publication_counter] =
        {
          year: publication.year,
          authors: publication.authors_to_string,
          title: publication.title,
          species: publication.fetch_relevant_species,
          url: url
        }
      publication_counter += 1
    end

    publication_json.as_json
  end

  def self.rss_feed
    rss_results = []
    rss = Nokogiri::HTML.parse(open('https://pubmed.ncbi.nlm.nih.gov/rss/search/1hSsbZPB1F1kLEzmTm8Yf6P_jXE0n1z6LR7hHTYKHI1-h2Q9cd/?limit=15&utm_campaign=pubmed-2&fc=20200513061319'))

    rss.css('item').each do |result|

      doi = ''
      result.css('identifier').each do |identifier|
        if identifier.content.include?('doi')
          doi = identifier.content
        else
          next
        end
      end

      this_result = {
        title: result.at_css('title').content,
        link: "https://#{doi.gsub('doi:', 'doi.org/')}",
        abstract: result.at_css('description').content,
        date: result.at_css('pubdate').content.to_s.scan(/\d{4}/)[0],
        authors: []
      }

      result.css('creator').each do |creator|
        this_result[:authors] << creator.content
      end

      this_result[:authors] = this_result[:authors].join(', ')
      rss_results.push(this_result)
    end
    rss_results
  end

  def self.fetch_ncbi_publications(ids_json, taxon)
    ids = ids_json['esearchresult']['idlist']
    result = Nokogiri::XML(open("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=#{ids.join(',')}&retmode=xml&api_key=#{Rails.application.credentials[:nih][:api_key]}"))
    result.xpath('//ArticleId').each do |id_entry|
      next unless id_entry.attributes['IdType'].value == 'doi'

      doi = id_entry.content
      publication = find_by(doi: doi)
      publication ||= create(doi: doi)

      if publication.taxa.include?(taxon) # update relation
        recent_pub_relation = publication.publication_taxons.where('taxon_id = ?', taxon.id)
        recent_pub_relation.update(updated_at: Time.now)
      else # create relation
        begin
          publication.authors.each do |author|
            JSON.parse(author.gsub('=>', ':'))
          end
        rescue => e
          p e.inspect
          p publication.authors
        end

        publication.taxa << taxon
      end
    end
  end

  def self.find_doi(authors_and_year, title_containing_string)
    ascii_query = Publication.encode(authors_and_year)
    Retryable.retryable(tries: 3, on: [OpenURI::HTTPError, Timeout::Error, Errno::ENETUNREACH]) do
      metadata_json = HTTParty.get("https://api.crossref.org/works?mailto=#{Rails.application.credentials[:application_owner][:mail]}&query=#{ascii_query}").parsed_response

      results = metadata_json['message']['items']
      results[0...5].each do |result|
        begin
          title = result['title'][0].gsub("\n", '').downcase
          if title_containing_string.downcase.include?(title)
            return result['DOI']
          end
        rescue NoMethodError => e
          puts e.message
        end
      end
      return nil
    end
  end

  # PRIVATE METHODS
  private

  def resolve_doi_metadata
    doi = self.doi
    metadata_json = HTTParty.get("https://api.crossref.org/works?mailto=#{Rails.application.credentials[:application_owner][:mail]}&filter=doi:#{doi}").parsed_response
    year = nil
    title = nil
    authors = nil
    begin
      data = metadata_json['message']['items'][0]

      if data && data['DOI'].downcase == doi.downcase
        year = data['created']
        if year
          year = year['date-parts'][0][0].to_i
        end

        year_of_publishing = data['published-print']
        if year_of_publishing && (year && year_of_publishing['date-parts'][0][0].to_i < year)
          year = year_of_publishing['date-parts'][0][0].to_i
        end
        year_of_publishing = data['published-online']
        if year_of_publishing && (year && data['published-online']['date-parts'][0][0].to_i < year)
          year = data['published-online']['date-parts'][0][0].to_i
        end

        title = data['title'][0] if data['title']
        authors = data['author']
      end
    rescue NoMethodError, TypeError => e
      puts "Rescued: #{e.inspect}"
      puts 'Could not resolve doi metadata of doi: ' + self.doi
    end

    self.year = year
    self.title = title
    self.authors = authors
  end
end
