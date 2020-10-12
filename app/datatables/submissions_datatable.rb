class SubmissionsDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  def_delegators :@view, :link_to, :multiple_link_to, :accept_submission_path, :reject_submission_path, :submission_path

  def initialize(params, opts = {})
    @view = opts[:view_context]
    @user_role = opts[:user_role]
    super
  end

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      submission: { source: 'Submission.id', cond: :eq },
      request: { source: 'Submission.request_type' },
      species: { source: 'Taxon.scientific_name' },
      user: { source: 'User.user_name' },
      submitted: { source: 'Submission.created_at' }
    }
  end

  def data
    records.map do |record|
      {
        submission: link_to(record.id, submission_path(record.id)),
        request: record.request_type,
        species: record.species_name,
        user: record.user_name,
        submitted: record.created_at.to_date,
        actions: multiple_link_to(
          [
            {
              text: 'Accept',
              path: accept_submission_path(record.id)
            },
            {
              text: 'Reject',
              path: reject_submission_path(record.id)
            }
          ]
        )
      }
    end
  end

  def get_raw_records
    if @user_role == 'admin'
      Submission.includes(:user, :taxon)
                .references(:user, :taxon)
                .distinct
    else
      Submission.pending_submissions.includes(:user, :taxon)
                .references(:user, :taxon)
                .distinct
    end
  end

end
