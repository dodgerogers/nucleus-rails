module NucleusRails
  class ResponseAdapter
    attr_reader :controller

    def initialize(controller)
      @controller = controller
    end

    # entity: <NucleusCore::View::Response>
    def json(entity)
      controller.render(json: entity.content, **render_attributes(entity))
    end

    def html(entity)
      controller.render(:html, **render_attributes(entity))
    end

    def xml(entity)
      controller.render(xml: entity.content, **render_attributes(entity))
    end

    def text(entity)
      controller.render(plain: entity.content, **render_attributes(entity))
    end

    def pdf(entity)
      controller.send_data(entity.content, render_attributes(entity))
    end

    def csv(entity)
      controller.send_data(entity.content, render_attributes(entity))
    end

    def nothing(entity)
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
end
