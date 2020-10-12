# frozen_string_literal: true

class ServerJobsDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  def_delegators :@view, :link_to, :ppg_job_path, :blast_job_path

  def initialize(params, opts = {})
    @view = opts[:view_context]
    @current_user = opts[:current_user]
    super
  end

  def view_columns
    @view_columns ||= {
      job_type: { source: 'ServerJob.job_type', searchable: true, orderable: false },
      job_title: { orderable: false },
      submitted: { source: 'ServerJob.created_at' },
      status: { orderable: false }
    }
  end

  def data
    records.map do |record|
      title = if record.job.title.empty?
                'no title'
              else
                record.job.title
              end

      if record.job.class.name == 'PpgJob'
        {
          job_type: record.job.class.name,
          job_title: link_to(title, ppg_job_path(record.job.id), data: { turbolinks: false }),
          submitted: record.created_at,
          status: record.job.status
        }
      else
        {
          job_type: record.job.class.name,
          job_title: link_to(title, blast_job_path(record.job.id), data: { turbolinks: false }),
          submitted: record.created_at,
          status: record.job.status
        }
      end
    end
  end

  def get_raw_records
    current_ability = Ability.new(@current_user)
    ServerJob.accessible_by(current_ability)
  end

end
