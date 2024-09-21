require "rails"
require "nucleus_core"

module NucleusRails
  autoload :CLI, "nucleus_rails/cli"
  autoload :VERSION, "nucleus_rails/version"
  autoload :ResponseAdapter, "nucleus_rails/response_adapter"
  autoload :RequestAdapter, "nucleus_rails/request_adapter"
  autoload :Responder, "nucleus_rails/responder"
  autoload :Worker, "nucleus_rails/worker"

  NucleusCore.configure do |config|
    config.logger = Rails.logger
    config.default_response_format = :json
  end
end
