class PublicationsController < ApplicationController
  def index
    begin
      @rss_results = Publication.rss_feed
    rescue
      @rss_results = []
    end
  end

  def datatable
    render json: PublicationsDatatable.new(params, view_context: view_context)
  end
end
