module NucleusRails
  class ResponseAdapter
    attr_reader :controller

    CONTENT_TYPES = Mime::EXTENSION_LOOKUP
      .each_with_object({}) { |(k, v), acc| acc[k.to_sym] = v.to_s }
      .freeze

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
    # rubocop:disable Rails/OutputSafety, Metrics/AbcSize
    def call(entity)
      init_render_context(entity)

      requested_format = sanitize_format(entity.format)

      case requested_format
      when :html
        controller.render(html: entity.content.html_safe, **render_attributes(entity))
      when :text
        controller.render(plain: entity.content, **render_attributes(entity))
      when :json, :xml, :atom, :js
        controller.render(requested_format => entity.content, **render_attributes(entity))
      when *CONTENT_TYPES.keys
        controller.send_data(entity.content, render_attributes(entity))
      else
        controller.head(:no_content, render_attributes(entity))
      end
    end
    # rubocop:enable Rails/OutputSafety, Metrics/AbcSize

    private

    def sanitize_format(string)
      string.to_s&.downcase&.to_sym
    end

    def init_render_context(entity)
      render_headers(entity.headers)
    end

    def render_headers(headers={})
      (headers || {}).each do |k, value|
        formatted_key = k.to_s.gsub(/\s *|_/, "-")

        controller.response.set_header(formatted_key, value)
      end
    end

    def render_attributes(entity)
      entity
        .to_h
        .except(:format, :content)
        .tap do |attrs|
          default_filename = "#{entity.class.name.demodulize.downcase}.#{entity.format}"
          attrs[:filename] = entity.filename.presence || default_filename
          attrs[:content_type] = CONTENT_TYPES[sanitize_format(entity.format)]
        end
    end
  end
end
