module NucleusRails
  class ResponseAdapter
    attr_reader :controller

    # `controller` is an instance of either:
    # - ActionController::Base
    # - ActionController::API
    def initialize(controller)
      @controller = controller
    end

    # `entity` is an instance of `NucleusCore::View::Response`.
    # Which contains the following attributes:
    # - `content`: The body or content of the response.
    # - `format`: The data type of the response.
    # - `headers`: A hash representing HTTP headers for the response.
    # - `status`: The HTTP status code (e.g., 200, 404).
    # - `location`: The location header for redirection responses.
    # - `filename`: The name for any file downloads (optional).
    # - `type`: The MIME type of the response (e.g., "application/json").
    # - `disposition`: Content disposition (e.g., "inline" or "attachment").
    def json(entity)
      init_render_context(entity)

      controller.render(json: entity.content, **render_attributes(entity))
    end

    def html(entity)
      init_render_context(entity)

      controller.render(:html, **render_attributes(entity))
    end

    def xml(entity)
      init_render_context(entity)

      controller.render(xml: entity.content, **render_attributes(entity))
    end

    def text(entity)
      init_render_context(entity)

      controller.render(plain: entity.content, **render_attributes(entity))
    end

    def pdf(entity)
      init_render_context(entity)

      controller.send_data(entity.content, render_attributes(entity))
    end

    def csv(entity)
      init_render_context(entity)

      controller.send_data(entity.content, render_attributes(entity))
    end

    def nothing(entity)
      init_render_context(entity)

      controller.head(:no_content, render_attributes(entity))
    end

    private

    def init_render_context(entity)
      render_headers(entity.headers)
    end

    def render_headers(headers={})
      (headers || {}).each do |k, value|
        formatted_key = k.gsub(/\s *|_/, "-")

        controller.response.set_header(formatted_key, value)
      end
    end

    def render_attributes(entity)
      entity.to_h.except!(:format, :content, :type)
    end
  end
end
