# frozen_string_literal: true

class OrthogroupsController < ApplicationController
  def index
    @all_taxa = Orthogroup.all_taxa
    gon.all_taxa = @all_taxa.to_json
  end

  def datatable
    @all_taxa = Orthogroup.all_taxa
    render json: OrthogroupsDatatable.new(params, { view_context: view_context, all_taxa: @all_taxa })
  end

  def show
    @orthogroup = Orthogroup.find(params[:id])
    @function_realm = @orthogroup.function_realm
    @orthogroup_tree = @orthogroup.tree.fetch_ortho_tree
    gon.orthogroup_tree = @orthogroup_tree

    @taxon_functions = @orthogroup.retrieve_members_per_taxon
    gon.taxon_functions = @taxon_functions
  end

  def download_newick
    orthogroup = Orthogroup.find(params[:id])
    file_path = ActiveStorage::Blob.service.path_for(orthogroup.tree_file.key)
    send_file(file_path, filename: "#{orthogroup.identifier}_tree.txt", disposition: 'attachment', type: "text/plain")
  end

  def download_fasta
    orthogroup = Orthogroup.find(params[:id])
    file_path = ActiveStorage::Blob.service.path_for(orthogroup.sequence_file.key)
    send_file(file_path, filename: "#{orthogroup.identifier}.fasta", disposition: 'attachment', type: "text/plain")
  end
end
