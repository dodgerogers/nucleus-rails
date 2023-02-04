require "active_support"
require "action_controller/railtie"
require "nucleus_core"

module NucleusRails::Responder
  extend ActiveSupport::Concern
  include ActionController::MimeResponds
  include ActionController::ImplicitRender
  include NucleusCore::Responder

  included do
    before_action do |controller|
      init_responder(
        response_adapter: controller,
        request_format: controller.request&.format
      )
    end

    rescue_from Exception, with: :handle_exception
  end

  delegate :set_header, to: :response

  # entity: <Nucleus::ResponseAdapter>
  def render_json(entity)
    render(json: entity.content, **render_attributes_from(entity))
  end

  def render_xml(entity)
    render(xml: entity.content, **render_attributes_from(entity))
  end

  def render_text(entity)
    render(plain: entity.content, **render_attributes_from(entity))
  end

  def render_pdf(entity)
    send_data(entity.content, render_attributes_from(entity))
  end

  def render_csv(entity)
    send_data(entity.content, render_attributes_from(entity))
  end

  def render_nothing(entity)
    head(:no_content, render_attributes_from(entity))
  end

  private

  def render_attributes_from(entity)
    {
      headers: entity.headers,
      status: entity.status,
      location: entity.location
    }
  end
end
