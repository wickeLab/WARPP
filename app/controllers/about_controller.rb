# frozen_string_literal: true

class AboutController < ApplicationController
  def warpp
    @all_ortho_taxa = Orthogroup.all_taxa.sort.to_json
    gon.all_ortho_taxa = @all_ortho_taxa
    @manual = Rails.root.join('data', 'WARPP_manual.md')
  end

  def parasitic_plant_biology; end
end
