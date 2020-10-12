namespace :taxon do
  desc 'Load family data from GBIF'
  task :add_family, [:family_name] => [:environment] do |_t, args|
    Taxon.add_family_via_GBIF(args[:family_name])
  end

  desc 'Load family data (genus and below) with static family entry'
  task :add_genera, %i[family_name genera] => [:environment] do |_t, args|
    family = Taxon.create(scientific_name: args[:family_name])
    args[:genera].split(' ').each do |genus_name|
      puts 'Creating entry and child entries for: ' + genus_name
      genus = Taxon.create(scientific_name: genus_name, parent: family)
      genus.retrieve_GBIF_children
    end
    Taxon.rebuild_depth_cache!
  end

  desc 'Destroy family'
  task :destroy_family, [:family_name] => [:environment] do |_t, args|
    Taxon.destroy_family_data(args[:family_name])
  end

  desc 'Read genome sizes'
  task load_genome_sizes: :environment do |_t|
    Taxon.add_genome_sizes
  end

  desc 'Read chromosome numbers'
  task load_chromosome_numbers: :environment do |_t|
    Dir["#{Rails.root.join('data', 'chromosome_numbers')}/*"].each do |input_csv|
      row_sep = if input_csv.include?('Boraginaceae')
                  "\r\r"
                else
                  "\r\r\n"
                end

      CSV.open(input_csv, headers: true, col_sep: ',', quote_char: '"', row_sep: row_sep).each do |row|
        family_entry = Taxon.where(scientific_name: row['family']).first_or_create
        genus_entry = Taxon.where(scientific_name: row['genus']).first_or_create
        genus_entry.parent = family_entry unless genus_entry.parent

        resolved_name = row['resolved_name']
        split_name = resolved_name.scan(/[a-z.()]+/i)
        scientific_name = split_name[0..1].join(' ')
        authorship = split_name[2..-1].join(' ')

        species_entry = Taxon.where(scientific_name: scientific_name).first_or_create
        species_entry.parent = genus_entry unless species_entry.parent

        next if species_entry.chromosome_number

        species_entry.authorship = authorship unless species_entry.authorship
        species_entry.save

        puts 'Processing... ' + species_entry.scientific_name

        chromosome_number = row['sporophytic']
        if chromosome_number.blank?
          chromosome_number = (row['parsed_n'].to_i * 2).to_s
        end

        info_entry = ChromosomeNumber.create(taxon: species_entry, information_type: :chromosome_number, information: chromosome_number)

        next unless row['reference']

        if row['reference'].include?(';') && row['reference'].scan(/[12][890]\d{2}(?!\d)/).length > 1
          references = row['reference'].split(';')
        else
          references = [row['reference']]
        end

        references.each do |reference|
          authors_year_title_containing_string = reference.scan(/.+[12][890]\d{2}[a-z]?\)?\.?:?[\p{L}\s-]+\(?[\p{L}\s]*\d?\)?\.?/i)[0]

          if authors_year_title_containing_string
            if authors_year_title_containing_string
              title_split = authors_year_title_containing_string.scan(/\p{L}[\p{L}\s-]+\(?[\p{L}\s]*\d?\)?\.?/)
            end
            if title_split && title_split.length > 1
              title = title_split[-1].strip
            end
          else
            authors_year_title_containing_string = reference.scan(/.+[12][890]\d{2}/)[0]
          end

          year = reference.scan(/[12][890]\d{2}(?!\d)/)[0]
          if authors_year_title_containing_string
            authors = authors_year_title_containing_string.split(/\d/)[0]
          end

          if year && authors
            author_last_names = authors.scan(/[\p{L}]{2,}-?[\p{L}]*/i).map(&:capitalize).join(' ')
            doi = Publication.find_doi("#{author_last_names} #{year} #{title}", row['reference'])
          end

          if doi
            publication = Publication.where(doi: doi).first_or_create
          elsif author_last_names && title && !title.blank? && year
            if title.length > 10
              publication = Publication.where(title: title, year: year.to_i).first_or_create do |ref|
                authors = []
                author_last_names = author_last_names.split(' ')
                author_last_names.each do |last_name|
                  sequence = author_last_names.index(last_name).zero? ? 'first' : 'additional'
                  authors << {'given' => '', 'family' => last_name, 'sequence' => sequence, 'affiliation' => ''}
                end
                ref.authors = authors
              end
            end
          end

          if publication&.valid? && !info_entry.publications.include?(publication)
            info_entry.publications << publication
          end
        end
      end
    end
  end
end
