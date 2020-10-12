# frozen_string_literal: true

class TaxonController < ApplicationController
  def browser_index
    @images = Dir["#{Rails.root.join('app', 'assets', 'images', 'oro_slideshow')}/*"]
              .map { |image_path| image_path.scan(/oro_slideshow.*/)[0] }

    all_families = Taxon.families
    @families = Taxon::FAMILY_ORDER.map { |family| all_families.where(scientific_name: family).exists? ? [family, true] : [family, false] }
  end

  def index
    @family = params[:family]
    gon.family = @family

    @max_depth = Taxon.max_depth(@family)
    gon.max_depth = @max_depth

    if params[:filter_options]
      filter_options = JSON.parse(params[:filter_options])
      @all_oros, @information_score = Taxon.fetch_filtered_tree_JSON(params[:family], filter_options)
    else
      @all_oros, @information_score = Taxon.fetch_filtered_tree_JSON(params[:family])
    end

    gon.all_oros = @all_oros
    gon.information_score = @information_score
  end

  def show
    species_entry = Taxon.find(params[:id])
    @species, @family, @genus = species_entry.scientific_name
    if species_entry.ancestry?
      @family, @genus = species_entry.family, species_entry.genus
    end
    @authorship = species_entry.authorship

    @unique_references, @info_with_ref_numbers, @parasites_with_ref_numbers, @hosts_with_ref_numbers = species_entry.collect_references
    @parasite_header = @hosts_with_ref_numbers.length > 0 ? 'Epiparasites' : 'Parasites'

    if species_entry.gen_bank
      @genbank_info = species_entry.gen_bank.collect_info_for_species
    end

    @recent_publications = Publication.fetch_publications_as_json(species_entry.publications)
    @recent_publications = @recent_publications.sort_by { |_k, v| -v['year'] }

    @species_id = species_entry.id

    # plant images
    @images = species_entry.plant_images
    @image_attributions = species_entry.collect_photo_information
    gon.image_attributions = @image_attributions.to_json

    gbif_map_url, gbif_species_url = build_GBIF_URL(@species)
    gon.gbif_map_url = gbif_map_url
    gon.gbif_species_url = gbif_species_url
  end

  def show_alternatives
    @alternatives = []
    potential_alternatives = Taxon.kinda_spelled_like(params[:scientific_name])

    if potential_alternatives.length > 0
      if potential_alternatives.first.children?
        redirect_to show_children_taxa_path(scientific_name: potential_alternatives.first.scientific_name)
      elsif potential_alternatives.length == 2 # bc species as well as genus
        redirect_to taxon_path(id: potential_alternatives.first.id)
      end
    end

    potential_alternatives.each do |alternative|
      @alternatives << alternative unless alternative.children?
    end
  end

  def show_children
    @species = Taxon.find_by scientific_name: params[:scientific_name]
    @scientific_name = params[:scientific_name]
    @children = @species.children
  end

  def new
    redirect_to home_index_path unless user_signed_in?

    if current_user.group_member? || current_user.admin?
      @family_genera = Taxon.collect_genera
      gon.family_genera = @family_genera
      gon.current_user = current_user.id
    else
      redirect_to root_path
    end
  end

  def edit
    unless user_signed_in? && (current_user.group_member? || current_user.admin?)
      redirect_to home_index_path
    end

    taxon = Taxon.find(params[:id])

    @scientific_name = taxon.scientific_name
    @hosts = taxon.hosts.pluck(:scientific_name)
    @parasites = taxon.parasites.pluck(:scientific_name)

    gon.watch.hosts = @hosts
    gon.watch.parasites = @parasites
    gon.species_id = params[:id]
    gon.current_user = current_user.id
  end

  def search
    keyword = params[:keyword]

    if keyword.empty?
      redirect_to taxonomy_browser_index_path
      return
    end

    keywords = keyword.split(' ')

    lifetrait_values = Lifestyle::LIFESTYLES + Lifespan::LIFESPANS + Habit::HABITS
    if (lifetrait_values & keywords).length > 0 # search for family/families with filters
      if (Taxon.family_names & keywords).length == 1
        family = (Taxon.family_names & keywords)[0]
        keywords.delete(family)

        filter_options = { 'query_type' => 'independently', 'information_score' => {}, 'lifestyle' => {}, 'lifespan' => {} }
        lifespan_counter = 1
        lifestyle_counter = 1

        keywords.each do |this_keyword|
          if Lifespan::LIFESPANS.include?(this_keyword)
            filter_options['lifespan'][lifespan_counter] = this_keyword
            lifespan_counter += 1
          elsif Lifestyle::LIFESTYLES.include?(this_keyword)
            filter_options['lifestyle'][lifestyle_counter] = this_keyword
            lifestyle_counter += 1
          end
        end

        filter_options = filter_options.to_json
        redirect_to taxonomy_browser_path(family: family, filter_options: filter_options)
      else
        redirect_to list_multifamily_search_results_path
      end
    elsif (Taxon.family_names & keywords).length > 1 # search for multiple families without filters

    else
      @species = Taxon.find_by scientific_name: keyword
      if @species.nil?
        redirect_to show_alternatives_taxa_path(scientific_name: keyword)
      elsif @species.family?
        family = @species.scientific_name
        redirect_to taxonomy_browser_path(family: family)
      elsif @species.children?
        redirect_to show_children_taxa_path(scientific_name: @species.scientific_name)
      else
        redirect_to taxon_path(id: @species.id)
      end
    end
  end

  def multifamily_search_list
    # TODO
  end

  def get_filtered_tree
    parsed_parameters = JSON.parse(params.keys[0])
    family = parsed_parameters['family']
    filter_options = parsed_parameters['filter_options']
    p filter_options
    @all_oros, @information_score = Taxon.fetch_filtered_tree_JSON(family, filter_options)
    render json: { all_oros: @all_oros, information_score: @information_score }
  end

  def build_GBIF_URL(scientific_name)
    taxon_key = Taxon.retrieve_GBIF_taxon_id(scientific_name)

    gbif_map_url = "https://api.gbif.org/v2/map/occurrence/density/{z}/{x}/{y}@3x.png?taxonKey=#{taxon_key}&bin=hex&squareSize=35&style=purpleYellow.poly"
    gbif_species_url = "https://www.gbif.org/species/#{taxon_key}"

    return gbif_map_url, gbif_species_url
  end
end
