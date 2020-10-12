class OrthogroupsDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  def_delegators :@view, :link_to, :orthogroup_path, :array_to_ul, :boolean_to_icon

  def initialize(params, opts = {})
    @view = opts[:view_context]
    @all_taxa = opts[:all_taxa]
    super
  end

  def view_columns
    taxa = [['Arabidopsis thaliana', { source: 'OrthogroupTaxon.members', orderable: false }]]
    taxa += (@all_taxa - ['Arabidopsis thaliana']).map do |taxon|
      [taxon, { orderable: false }]
    end
    taxa = taxa.to_h.symbolize_keys
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      orthogroup: { source: 'Orthogroup.identifier' },
      function_realm: { source: 'Orthogroup.function_realm', orderable: false }
    }.merge!(taxa)
  end

  def data
    records.map do |record|
      return_value = @all_taxa.map do |taxon|
        [taxon, boolean_to_icon(record.check_taxon_presence(taxon))]
      end

      return_value +=
        [
          ['orthogroup', link_to(record.identifier, orthogroup_path(record.id))],
          ['function_realm', array_to_ul(record.function_realm)]
        ]

      return_value.to_h.symbolize_keys
    end
  end

  def get_raw_records
    Orthogroup.all.includes(:orthogroup_taxons).references(:orthogroup_taxons)
  end

end