class GenomeBrowsersController < ApplicationController
  def index
    @genomes = Taxon::AVAILABLE_GENOME_BROWSERS.sort
  end

  def jbrowse
    taxon = params[:taxon].gsub(' ', '_').downcase
    locus = params[:locus]
    @genome_url = "https://parasiticplants.app/jbrowse/index.html?data=data/#{taxon}"
    @genome_url += "&loc=#{locus}" if locus
  end
end
