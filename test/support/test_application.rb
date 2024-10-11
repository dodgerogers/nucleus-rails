require "rails"
require "action_controller/railtie"

class TestView < NucleusCore::View
  def initialize(attrs={})
    super(attrs.slice(:name, :ids))
  end

  def json
    NucleusCore::View::Response.new(:json, content: { a: { nested: { hash: "value" } }, b: [4, 5, 6] })
  end

  def xml
    NucleusCore::View::Response.new(:xml, content: to_h)
  end

  def pdf
    pdf = <<-SQL.squish
      %PDF-1.
      trailer<</Root<</#{name}<</#{name}[<</MediaBox[0 0 3 3]>>]>>>>>>
    SQL

    NucleusCore::View::Response.new(:pdf, content: pdf, filename: "testview.pdf")
  end

  def csv
    NucleusCore::View::Response.new(:csv, content: "#{name}\n#{ids.join('-')}", filename: "textview.csv")
  end

  def text
    NucleusCore::View::Response.new(:text, content: "My name is #{name}, my ID's are #{ids.join(', ')}")
  end

  def html
    NucleusCore::View::Response.new(:html, content: "<h1>#{name}</h1><p>#{ids.join(', ')}</p>")
  end
end

class TestApplication < Rails::Application
  config.api_only = true
  config.middleware.use ActionDispatch::Cookies
  config.eager_load = :test
  config.hosts << "nucleus"
end

class TestCasesController < ActionController::API
  include NucleusRails::Responder

  def view_object
    render_response do |_req|
      TestView.new(name: "Bob", ids: [1, 2, 3])
    end
  end

  def response_object
    render_response do |_req|
      NucleusCore::View::Response.new(:nothing, headers: { "my_custom_headers" => "value" })
    end
  end

  def exception_raised
    render_response do |_req|
      raise StandardError, "exception..."
    end
  end

  def inline_syntax
    view = TestView.new(name: "Bob", ids: [1, 2, 3])

    render_entity(view)
  end
end

Rails.application.initialize!

Rails.application.routes.draw do
  get :view_object, to: "test_cases#view_object"
  get :response_object, to: "test_cases#response_object"
  put :exception_raised, to: "test_cases#exception_raised"
  post :inline_syntax, to: "test_cases#inline_syntax"
end
