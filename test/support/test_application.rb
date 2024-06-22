require "rails"
require "action_controller/railtie"

class TestView < NucleusCore::View
  def initialize(attrs={})
    super(attrs.slice(:name, :ids))
  end

  def json_response
    NucleusCore::View::Response.new(:json, content: { a: { nested: { hash: "value" } }, b: [4, 5, 6] })
  end

  def xml_response
    NucleusCore::View::Response.new(:xml, content: to_h)
  end

  def pdf_response
    pdf = <<-SQL.squish
      %PDF-1.
      trailer<</Root<</#{name}<</#{name}[<</MediaBox[0 0 3 3]>>]>>>>>>
    SQL

    NucleusCore::View::Response.new(:pdf, content: pdf)
  end

  def csv_response
    NucleusCore::View::Response.new(:csv, content: "#{name}\n#{ids.join('-')}")
  end

  def text_response
    NucleusCore::View::Response.new(:text, content: "My name is #{name}, my ID's are #{ids.join(', ')}")
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
    execute do |_req|
      TestView.new(name: "Bob", ids: [1, 2, 3])
    end
  end

  def show
    execute do |_req|
      NucleusCore::View::Response.new(:nothing, headers: { "my_custom_headers" => "value" })
    end
  end

  def edit
    execute do |_req|
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
