# frozen_string_literal: true

class AboutController < ApplicationController
  def warpp
    @manual = Rails.root.join('data', 'WARPP_manual.md')
  end

  def parasitic_plant_biology; end
end
