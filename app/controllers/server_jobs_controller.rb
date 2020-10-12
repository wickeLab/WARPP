class ServerJobsController < ApplicationController
  def index; end

  def datatable
    render json: ServerJobsDatatable.new(params, { view_context: view_context, current_user: current_user })
  end
end
