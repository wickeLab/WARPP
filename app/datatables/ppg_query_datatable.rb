# frozen_string_literal: true

class PpgQueryDatatable < AjaxDatatablesRails::ActiveRecord

  def view_columns
    @view_columns ||= {
      query_name: { source: 'PpgQuery.query_name' },
      functional_assignment: { source: 'PpgQuery.functional_assignment' },
      median_functionality_score: { source: 'PpgQuery.median_functionality_score' }
    }
  end

  def data
    records.map do |record|
      {
        query_name: record.query_name,
        functional_assignment: record.functional_assignment,
        median_functionality_score: record.median_functionality_score
      }
    end
  end

  def get_raw_records
    PpgQuery.all
  end

end
