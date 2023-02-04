require "rails"
require "action_controller/railtie"
require "nucleus_core/response_adapter"

class TestView < NucleusCore::View
  def initialize(attrs={})
    super(attrs)
  end

  def json_response
    NucleusCore::JsonResponse.new(content: { a: { nested: { hash: "value" } }, b: [4, 5, 6] })
  end

  def xml_response
    NucleusCore::XmlResponse.new(content: to_h)
  end

  def pdf_response
    pdf = <<-SQL.squish
      %PDF-1.
      trailer<</Root<</#{name}<</#{name}[<</MediaBox[0 0 3 3]>>]>>>>>>
    SQL

    NucleusCore::PdfResponse.new(content: pdf)
  end

  def csv_response
    NucleusCore::PdfResponse.new(content: "#{name}\n#{ids.join('-')}")
  end

  def text_response
    NucleusCore::PdfResponse.new(content: "My name is #{name}, my ID's are #{ids.join(', ')}")
  end
end

class TestApplication < Rails::Application
  config.api_only = true
  config.middleware.use ActionDispatch::Cookies
  config.eager_load = :test
  config.hosts << "nucleus"
end

class UsersController < ActionController::API
  include NucleusRails::Responder

  def index
    handle_response do
      TestView.new(name: "Bob", ids: [1, 2, 3])
    end
  end

  def show
    handle_response do
      NucleusCore::NoResponse.new(headers: { "my_custom_headers" => "value" })
    end
  end

  def edit
    handle_response do
      raise StandardError, "exception..."
    end
  end
end

Rails.application.initialize!

Rails.application.routes.draw do
  get :users, to: "users#index"
  get :user, to: "users#show"
  put :user, to: "users#edit"
end
