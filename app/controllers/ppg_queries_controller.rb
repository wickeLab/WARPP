class PpgQueriesController < ApplicationController
  def datatable
    render json: PpgQueryDatatable.new(params)
  end
end
