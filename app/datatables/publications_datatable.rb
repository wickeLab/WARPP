class PublicationsDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  def_delegators :@view, :link_to, :links_as_ul_without_partial

  def initialize(params, opts = {})
    @view = opts[:view_context]
    super
  end

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      year: { source: 'Publication.year', cond: :eq },
      authors: { source: 'Publication.authors' },
      title: { source: 'Publication.title' },
      species: { source: 'Taxon.scientific_name', orderable: false }
    }
  end

  def data
    records.map do |record|
      {
        year: record.year,
        authors: record.authors_to_string,
        title: link_to(record.title, record.fetch_url, target: '_blank'),
        species: links_as_ul_without_partial(record.fetch_relevant_species)
      }
    end
  end

  def get_raw_records
    Publication.all.includes(:taxa).references(:taxa).distinct
  end

end
