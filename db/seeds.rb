User.create(user_name: "guest", email: Rails.application.credentials[:user_info][:guest][:mail], password: Rails.application.credentials[:user_info][:guest][:password])
User.create(user_name: "Lara", email: Rails.application.credentials[:user_info][:lara][:mail], password: Rails.application.credentials[:user_info][:lara][:password], role: "admin")
User.create(user_name: "Susann", email: Rails.application.credentials[:user_info][:susann][:mail], password: Rails.application.credentials[:user_info][:susann][:password], role: "group_member")
User.create(user_name: "Peter", email: Rails.application.credentials[:user_info][:peter][:mail], password: Rails.application.credentials[:user_info][:peter][:password], role: "group_member")
User.create(user_name: "Svenja", email: Rails.application.credentials[:user_info][:svenja][:mail], password: Rails.application.credentials[:user_info][:svenja][:password], role: "group_member")

####
# FETCH OROBANCHACEAE
TaxonomicLevel.create(scientific_name: "Orobanchaceae")

parent_order = ""
CSV.foreach(Rails.root.join('lib', 'seeds', 'OrobTaxonListByClade.txt'), :headers => false, :col_sep => "\t") do |row|
  root = TaxonomicLevel.find_by scientific_name: "Orobanchaceae"
  if row[0] != nil
    parent_order = TaxonomicLevel.create(scientific_name: row[0], parent: root)
  end
  TaxonomicLevel.create(scientific_name: row[1], parent: parent_order)
end

# fetch ncbi oro entries
oros = HTTParty.get("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=taxonomy&term=Orobanchaceae[orgn]&retmode=json&retmax=10000&api_key=#{Rails.application.credentials[:nih][:api_key]}").parsed_response
ids = oros["esearchresult"]["idlist"]

ids.each do |id|
  taxonomic_information = nil
  while taxonomic_information == nil
    taxonomic_information = Nokogiri::XML(open("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=taxonomy&id=#{id}&retmode=xml&api_key=#{Rails.application.credentials[:nih][:api_key]}"))
  end

  if taxonomic_information.at_xpath('//Rank') && taxonomic_information.at_xpath('//Rank').content == "species"
    scientific_name = taxonomic_information.at_xpath("//ScientificName").content
    if scientific_name =~ /[A-Z][a-z]+\s[a-z]+/
      p "Creating " + scientific_name
      species =  TaxonomicLevel.find_by scientific_name: scientific_name
      unless species
        species = TaxonomicLevel.create(scientific_name: scientific_name)
        species.taxonomic_information = taxonomic_information
      end
    end
  end
end

# fetch information on host/parasite relationships (provided by us)
def validate_name(scientific_name)
  begin
    url = "https://www.ncbi.nlm.nih.gov/taxonomy/?term=#{scientific_name}"
    result_page = Nokogiri::HTML.parse(open(url))
    result_page = result_page.to_s

    if result_page.scan(/term\swas\snot\sfound/).length > 0 || !scientific_name.include?(" ")
      scientific_name = nil
    elsif result_page.scan(/Showing\sresults\sfor.+Your\ssearch\sfor.+retrieved no results/).length > 0
      result = result_page.scan(/Showing\sresults\sfor.+\./)[0].scan(/<i>.+<\/i>/)[0]
      scientific_name = Sanitize.fragment(result).capitalize
    elsif result_page.scan(/Showing\sresults\sfor.+Search\sinstead\sfor.+/).length > 0
      result = result_page.scan(/Showing\sresults\sfor.+\./)[0].scan(/<i>.+<\/i>/)[0]
      scientific_name = Sanitize.fragment(result).capitalize
    end
    return scientific_name
  rescue => e
    puts e.inspect
    puts "Could not validate name: " + scientific_name
    return nil
  end
end

p "Processing host list now."

row_count = 0
headers = []
File.open(Rails.root.join('lib', 'seeds', 'host_list.tsv')).each do |line|
  if row_count == 0
    headers = line.chomp.split("\t")
    row_count += 1
  else
    row_count += 1

    begin
      row = headers.zip(line.chomp.split("\t")).to_h
    rescue Encoding::InvalidByteSequenceError, ArgumentError => e
      encoded_line = line.encode("UTF-8", invalid: :replace, undef: :replace)
      row = headers.zip(encoded_line.chomp.split("\t")).to_h
      puts "Rescued: #{e.inspect}"
    end

    oro_species = row["Species"].gsub("_", " ")
    puts "Processing entry for: " + oro_species
    if row["Host"]
      host = row["Host"]
    elsif row["Host_fam"]
      host = row["Host_fam"]
    end

    scientific_name = validate_name(oro_species)
    oro_entry = TaxonomicLevel.find_by scientific_name: scientific_name
    if scientific_name && !oro_entry
      oro_entry = TaxonomicLevel.create(scientific_name: scientific_name)
    end

    host_name = validate_name(host)
    host_entry = TaxonomicLevel.find_by scientific_name: host_name
    if host_name && !host_entry
      host_entry = TaxonomicLevel.create(scientific_name: host_name)
    end

    if oro_entry && host_entry
      unless oro_entry.hosts.include?(host_entry)
        oro_entry.hosts << host_entry
        oro_entry.information_status = "reliable"
        oro_entry.save
      end

      relationship_entry = ParasiticRelationship.find_by host: host_entry, parasite: oro_entry

      pub_titles = row["pub_title"]

      if pub_titles
        pub_titles = pub_titles.split("|")
        pub_dois = row["DOIs"]

        if pub_dois
          pub_dois = pub_dois.split("|")
          pub_dois.each do |doi|
            begin
              publication = Publication.find_by doi: doi
              unless publication
                publication = Publication.create(doi: doi)
              end

              if publication && !relationship_entry.publications.include?(publication)
                relationship_entry.publications << publication
              end
            rescue ActiveRecord::RecordInvalid => e
              puts e.inspect
              puts oro_entry.scientific_name
              puts row
            end
          end
        end

        if relationship_entry.publications.empty? && !row["pub_year"].empty? && !row["pub_authors"].empty?
          pub_years = row["pub_year"].split("|")
          pub_authors = row["pub_authors"].split("|")
          (0...pub_titles.length).each do |i|
            title = pub_titles[i]
            year = pub_years[i]
            authors = pub_authors[i].split("&")
            formatted_authors = []

            (0...authors.length).each do |i_sec|
              author = authors[i_sec]
              author_info = author.split(",")

              if author_info.length == 2
                given = author_info[1]
                family = author_info[0]
                i_sec == 0 ? sequence = "first" : sequence = "additional"
                affiliation = []
              else
                given = ""
                family = ""
                i_sec == 0 ? sequence = "first" : sequence = "additional"
                affiliation = author_info[0]
              end

              formatted_authors << {"given" => given, "family" => family, "sequence" => sequence, "affiliation" => affiliation}
            end

            publication = Publication.find_by year: year, title: title

            unless publication
              publication = Publication.create(year: year, title: title, authors: formatted_authors)
            end

            if publication && !relationship_entry.publications.include?(publication)
              relationship_entry.publications << publication
            end
          end
        end
      end
    end
  end
end

lifespan_translation = {"0" => "annual", "1" => "biennial", "2" => "perennial"}

CSV.foreach(Rails.root.join('lib', 'seeds', 'OROB_lifespan.txt'), :headers => true, :col_sep => "\t") do |row|
  species_entry = TaxonomicLevel.find_by scientific_name: row["#species"].gsub("_", " ")
  if species_entry && row["lifespan"]
    if row["lifespan"].include?(",")
      lifespan = row["lifespan"].split(",")[0]
    else
      lifespan = row["lifespan"]
    end
    species_entry.lifespan = lifespan_translation[lifespan]
    species_entry.information_status = "reliable"
    species_entry.save
  else
    p row["#species"]
  end
end

lifestyle_translation = {"0" => "autotroph", "1" => "facultative", "2" => "obligate", "3" => "holoparasitic"}

CSV.foreach(Rails.root.join('lib', 'seeds', 'OROB_lifestyle.txt'), :headers => true, :col_sep => "\t") do |row|
  species_entry = TaxonomicLevel.find_by scientific_name: row["#species"].gsub("_", " ")
  if species_entry && row["lifestyle"]
    if row["lifestyle"].include?(",")
      lifestyle = row["lifestyle"].split(",")[0]
    else
      lifestyle = row["lifestyle"]
    end
    species_entry.lifestyle = lifestyle_translation[lifestyle]
    species_entry.information_status = "reliable"
    species_entry.save
  else
    p row["#species"]
  end
end

####
# FETCH OTHER PARASITIC PLANT FAMILIES

TaxonomicLevel.add_family_via_GBIF("Convolvulaceae")
TaxonomicLevel.add_family_via_GBIF("Mitrastemonaceae")
TaxonomicLevel.add_family_via_GBIF("Apodanthaceae")
TaxonomicLevel.add_family_via_GBIF("Cytinaceae")
TaxonomicLevel.add_family_via_GBIF("Rafflesiaceae")
TaxonomicLevel.add_family_via_GBIF("Krameriaceae")
TaxonomicLevel.add_family_via_GBIF("Cynomoriaceae")

TaxonomicLevel.add_family_via_GBIF("Erythropalaceae")
TaxonomicLevel.add_family_via_GBIF("Ximeniaceae")
TaxonomicLevel.add_family_via_GBIF("Olacaceae")
TaxonomicLevel.add_family_via_GBIF("Misodendraceae")
TaxonomicLevel.add_family_via_GBIF("Schoepfiaceae")
TaxonomicLevel.add_family_via_GBIF("Loranthaceae")
TaxonomicLevel.add_family_via_GBIF("Opiliaceae")
TaxonomicLevel.add_family_via_GBIF("Comandraceae")
TaxonomicLevel.add_family_via_GBIF("Thesiaceae")
TaxonomicLevel.add_family_via_GBIF("Cervantesiaceae")
TaxonomicLevel.add_family_via_GBIF("Nanodeaceae")
TaxonomicLevel.add_family_via_GBIF("Santalaceae")
TaxonomicLevel.add_family_via_GBIF("Amphorogynaceae")
TaxonomicLevel.add_family_via_GBIF("Viscaceae")
TaxonomicLevel.add_family_via_GBIF("Balanophoraceae")

TaxonomicLevel.add_family_via_GBIF("Hydnoraceae")
TaxonomicLevel.add_family_via_GBIF("Lauraceae")

TaxonomicLevel.rebuild_depth_cache!

