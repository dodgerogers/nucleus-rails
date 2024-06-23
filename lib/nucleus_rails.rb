require "nucleus_core"

module NucleusRails
  autoload :CLI, "nucleus_rails/cli"
  autoload :VERSION, "nucleus_rails/version"
  autoload :ResponseAdapter, "nucleus_rails/response_adapter"
  autoload :RequestAdapter, "nucleus_rails/request_adapter"
  autoload :Responder, "nucleus_rails/responder"
  autoload :Worker, "nucleus_rails/worker"
end
