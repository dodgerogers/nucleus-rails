require "active_record"
require "rails"

module NucleusRails
  autoload :CLI, "nucleus_rails/cli"
  autoload :VERSION, "nucleus_rails/version"
  autoload :Responder, "nucleus/responder"
  autoload :NucleusCore, "nucleus_core"

  NucleusCore.configure do |config|
    config.logger = Rails.logger
    config.exceptions_map = {
      not_found: ActiveRecord::RecordNotFound,
      unprocessable: ActiveRecord::ActiveRecordError
    }
  end
end
