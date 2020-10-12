# frozen_string_literal: true

class ServerJob < ApplicationRecord
  # ASSOCIATIONS
  belongs_to :user
  belongs_to :job, polymorphic: true

  # CALLBACKS
  before_destroy :destroy_dependent

  # PRIVATE METHODS
  private

  def destroy_dependent
    job.destroy
  end
end
