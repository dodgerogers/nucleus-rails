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

    NucleusCore::View::Response.new(:pdf, content: pdf, filename: "#{self.class.name.downcase}.pdf")
  end

  def csv
    NucleusCore::View::Response.new(
      :csv,
      content: "#{name}\n#{ids.join('-')}",
      filename: "#{self.class.name.downcase}.csv"
    )
  end

  def text
    NucleusCore::View::Response.new(:text, content: "My name is #{name}, my ID's are #{ids.join(', ')}")
  end

  def html
    NucleusCore::View::Response.new(:html, content: "<h1>#{name}</h1><p>#{ids.join(', ')}</p>")
  end

  def png
    NucleusCore::View::Response.new(:png, content: File.read("../test/support/files/example.png"))
  end

  def svg
    content = <<-SVG.squish
      <svg viewBox=".5 .5 3 4" fill="none" stroke="#20b2a" stroke-linecap="round">
        <path d="M1 4h-.001 V1h2v.001 M1 2.6 h1v.001"/>
      </svg>
    SVG

    NucleusCore::View::Response.new(:svg, content: content, filename: "#{self.class.name.downcase}.svg")
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

  def block_syntax
    render_response do |_req|
      TestView.new(name: "Bob", ids: [1, 2, 3])
    end
  end

  def inline_syntax
    view = TestView.new(name: "Bob", ids: [1, 2, 3])

    render_entity(view)
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
end

Rails.application.initialize!

Rails.application.routes.draw do
  get :block_syntax, to: "test_cases#block_syntax"
  get :response_object, to: "test_cases#response_object"
  put :exception_raised, to: "test_cases#exception_raised"
  post :inline_syntax, to: "test_cases#inline_syntax"
end
