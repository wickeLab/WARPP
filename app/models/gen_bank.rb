class GenBank < ApplicationRecord
  extend Ascii

  # ASSOCIATIONS
  belongs_to :taxon

  # CALLBACKS
  before_create :fetch_genbank_information_from_ncbi

  # INSTANCE METHODS
  def collect_info_for_species
    scientific_name = taxon.scientific_name

    scientific_name_ascii = GenBank.encode(scientific_name).gsub(' ', '+')
    general_search_nucleotide = "https://www.ncbi.nlm.nih.gov/nuccore/?term=#{scientific_name_ascii}[Organism]"
    general_search_sra = "https://www.ncbi.nlm.nih.gov/sra/?term=#{scientific_name_ascii}[Organism]"
    general_search_genome = "https://www.ncbi.nlm.nih.gov/genome/?term=#{scientific_name_ascii}[Organism]"
    genbank_info = {}

    unless plastome.nil?
      genbank_info['plastome'] = [plastome, general_search_nucleotide + 'plastid[filter]']
    end

    unless est.nil?
      genbank_info['est'] = [est, general_search_nucleotide + 'is_est[filter]']
    end

    unless mtdna.nil?
      genbank_info['mtdna'] = [mtdna, general_search_nucleotide + 'mitochondrion[filter]']
    end

    unless others.nil?
      genbank_info['others'] = [others, general_search_nucleotide]
    end

    genbank_info['sra'] = [sra, general_search_sra] unless sra.nil?

    if whole_genome
      genbank_info['whole_genome'] = [whole_genome, general_search_genome]
    end

    genbank_info
  end

  # PRIVATE METHODS
  private

  def fetch_genbank_information_from_ncbi
    begin
      ########################
      ## EST & plastome & mtdna

      scientific_name_ascii = GenBank.encode(taxon.scientific_name)
      key = Rails.application.credentials[:nih][:api_key]

      begin
        overall = HTTParty.get("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=nuccore&term=#{scientific_name_ascii}[Organism]&rettype=count&api_key=#{key}").parsed_response
        overall = overall['esearchresult']['count'].to_i
      rescue NoMethodError
        overall = 0
      end

      begin

        est_count = HTTParty.get("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=nuccore&term=#{scientific_name_ascii}[Organism]+is_est[filter]&rettype=count&api_key=#{key}").parsed_response
        est_count = est_count['esearchresult']['count'].to_i
      rescue NoMethodError
        est_count = 0
      end

      begin
        plastome_count = HTTParty.get("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=nuccore&term=#{scientific_name_ascii}[Organism]+plastid[filter]&rettype=count&api_key=#{key}").parsed_response
        plastome_count = plastome_count['esearchresult']['count'].to_i
      rescue NoMethodError
        plastome_count = 0
      end

      begin
        mtdna_count = HTTParty.get("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=nuccore&term=#{scientific_name_ascii}[Organism]+mitochondrion[filter]&rettype=count&api_key=#{key}").parsed_response
        mtdna_count = mtdna_count['esearchresult']['count'].to_i
      rescue NoMethodError
        mtdna_count = 0
      end

      overall -= (est_count + plastome_count + mtdna_count)

      whole_genome_search = HTTParty.get("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=genome&term=#{scientific_name_ascii}&rettype=xml&api_key=#{key}")
      whole_genome = whole_genome_search.empty? ? false : true

      ################
      ## SRA

      sra_count = HTTParty.get("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=sra&term=#{scientific_name_ascii}&rettype=count&api_key=#{key}")
      sra_count = sra_count['esearchresult']['count'].to_i

      self.est = est_count
      self.plastome = plastome_count
      self.mtdna = mtdna_count
      self.others = overall if overall.positive?
      self.sra = sra_count
      self.whole_genome = whole_genome
    rescue => e
      puts "Rescued: #{e.inspect}"
      puts "For: #{taxon.scientific_name}"
    end
  end
end
