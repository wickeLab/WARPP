class TreesController < ApplicationController
  def index
    @trait_reconstruction_trees = Tree.fetch_trac_trees
    gon.trait_reconstruction_trees = @trait_reconstruction_trees
  end
end
