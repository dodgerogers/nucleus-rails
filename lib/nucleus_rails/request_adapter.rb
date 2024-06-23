module NucleusRails
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
end
