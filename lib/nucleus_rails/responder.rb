require "active_support"
require "action_controller/railtie"
require "nucleus_core"
require "nucleus_rails/request_adapter"
require "nucleus_rails/response_adapter"

module NucleusRails::Responder
  extend ActiveSupport::Concern

  included do
    attr_accessor :responder

    before_action do |controller|
      @responder = NucleusCore::Responder.new(
        request_adapter: NucleusRails::RequestAdapter.new(controller),
        response_adapter: NucleusRails::ResponseAdapter.new(controller)
      )
    end

    rescue_from Exception do |e|
      responder.handle_exception(e)
    end

    def execute(&block)
      responder.execute(self, &block)
    end
  end
end
