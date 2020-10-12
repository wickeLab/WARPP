# frozen_string_literal: true

class StartServerJob
  include Sidekiq::Worker

  def perform(command)
    `#{command}`
  end
end