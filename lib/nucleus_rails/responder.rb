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

    # @param block [Proc] An optional block to pass for further customization of the execution.
    #
    # Block syntax
    # #########################################################################
    # def show
    #   execute do |req|
    #     ctx = MyOperation.call(id: req.params[:id])
    #
    #     return ctx unless ctx.success?
    #     return MyView.new(ctx.entity)
    #   end
    # end
    def execute(&block)
      responder.execute(self, &block)
    end

    # @param entity [Object] The entity to be rendered by the responder.
    #
    # Inline syntax
    # #########################################################################
    # def show
    #   ctx = MyOperation.call(id: req.params[:id])
    #
    #   return render_entity(ctx) unless ctx.success?
    #   return render_entity(MyView.new(ctx.entity))
    # end
    def render_entity(entity)
      request_context_attrs = responder.request_adapter&.call(self) || {}

      responder.request_context = NucleusCore::RequestAdapter.new(request_context_attrs)

      responder.render_entity(entity)
    end
  end
end
