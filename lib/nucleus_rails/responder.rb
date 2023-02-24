require "active_support"
require "action_controller/railtie"
require "nucleus_core"

module NucleusRails::Responder
  extend ActiveSupport::Concern

  class RequestAdapter
    attr_reader :controller

    def initialize(controller)
      @controller = controller
    end

    def call(_)
      {
        format: controller.request&.format&.to_sym,
        parameters: controller.params,
        request: controller.request
      }
    end
  end

  class ResponseAdapter
    attr_reader :controller

    def initialize(controller)
      @controller = controller
    end

    # entity: <Nucleus::ResponseAdapter status=Int content={} location=String headers={}>
    def render_json(entity)
      controller.render(json: entity.content, **render_attributes(entity))
    end

    def render_xml(entity)
      controller.render(xml: entity.content, **render_attributes(entity))
    end

    def render_text(entity)
      controller.render(plain: entity.content, **render_attributes(entity))
    end

    def render_pdf(entity)
      controller.send_data(entity.content, render_attributes(entity))
    end

    def render_csv(entity)
      controller.send_data(entity.content, render_attributes(entity))
    end

    def render_nothing(entity)
      controller.head(:no_content, render_attributes(entity))
    end

    def set_header(key, value)
      controller.response.set_header(key, value)
    end

    private

    def render_attributes(entity)
      {
        headers: entity.headers,
        status: entity.status,
        location: entity.location
      }
    end
  end

  included do
    attr_accessor :responder

    before_action do |controller|
      @responder = NucleusCore::Responder.new(
        request_adapter: RequestAdapter.new(controller),
        response_adapter: ResponseAdapter.new(controller)
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
