require "nucleus_rails/response_adapter"
require "active_record"

module NucleusRails
  autoload :CLI, "nucleus_rails/cli"
  autoload :VERSION, "nucleus_rails/version"

  NucleusCore.configure do |config|
    config.response_adapter = NucleusRails::ResponseAdapter
    config.logger = Rails.logger
    config.exceptions_map = {
      not_found: ActiveRecord::RecordNotFound,
      unprocessable: ActiveRecord::ActiveRecordError
    }
  end
end
