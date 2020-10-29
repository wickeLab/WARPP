# frozen_string_literal: true

module Exceptions
  class ServerJobError < StandardError; end
  class FileSizeError < ServerJobError; end
end
