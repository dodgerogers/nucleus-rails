require "active_support"
require "action_controller/railtie"
require "nucleus_core"

module NucleusRails::ResponseAdapter
  extend ActiveSupport::Concern
  include ActionController::MimeResponds
  include ActionController::ImplicitRender
  include NucleusCore::Responder

  included do
    before_action { set_request_format(request) }

    rescue_from Exception, with: :handle_exception
  end

  # <Nucleus::ResponseAdapter>
  # content: Hash, String
  # headers: Hash
  # status: Integer
  # location: String
  def render_json(entity)
    render(json: entity.content, **entity.to_h.except(:content))
  end

  def render_xml(entity)
    render(xml: entity.content, **entity.to_h.except(:content))
  end

  def render_text(entity)
    render(plain: entity.content, **entity.to_h.except(:content))
  end

  def render_pdf(entity)
    send_data(entity.content, entity.to_h.except(:content))
  end

  def render_csv(entity)
    send_data(entity.content, entity.to_h.except(:content))
  end

  def render_nothing(entity)
    head(:no_content, entity.to_h)
  end

  delegate :set_header, to: :response
end
