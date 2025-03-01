require "rails"
require "action_controller/railtie"

# TestView is a specialized view class for rendering entity data
# into various content formats such as JSON, XML, PDF, CSV, and more.
#
# This class subclasses `NucleusCore::View` and overrides its behavior
# to provide formatted responses for different content types.
#
# Key Features:
# - Supports multiple content formats including JSON, XML, CSV, HTML, and more.
# - Uses class methods to define format-specific content generation.
# - Dynamically defines instance methods for all supported content types.
# - Uses `NucleusRails::ResponseAdapter::CONTENT_TYPES` to determine valid formats.
#
# Example Usage:
#   view = TestView.new(name: "TestEntity", ids: [1, 2, 3])
#
#   view.json  # => { a: { nested: { hash: "value" } }, b: [4, 5, 6] }
#   view.html  # => "<h1>TestEntity</h1><p>1, 2, 3</p>"
#   view.csv   # => "TestEntity\n1-2-3"
#
# The class automatically generates instance methods for each content type
# based on the `NucleusRails::ResponseAdapter::CONTENT_TYPES` hash.
class TestView < NucleusCore::View
  def initialize(attrs={})
    super(attrs.slice(:name, :ids))
  end

  def self.json_content(_entity)
    { a: { nested: { hash: "value" } }, b: [4, 5, 6] }
  end

  def self.xml_content(entity)
    entity.to_h
  end

  def self.pdf_content(entity)
    <<-PDF.squish
      %PDF-1.
      trailer<</Root<</#{entity.name}<</#{entity.name}[<</MediaBox[0 0 3 3]>>]>>>>>>
    PDF
  end

  def self.csv_content(entity)
    "#{entity.name}\n#{entity.ids.join('-')}"
  end

  def self.txt_content(entity)
    "My name is #{entity.name}, my ID's are #{entity.ids.join(', ')}"
  end

  def self.text_content(entity)
    "My name is #{entity.name}, my ID's are #{entity.ids.join(', ')}"
  end

  def self.html_content(entity)
    "<h1>#{entity.name}</h1><p>#{entity.ids.join(', ')}</p>"
  end

  def self.svg_content(_entity)
    <<-SVG.squish
      <svg viewBox=".5 .5 3 4" fill="none" stroke="#20b2a" stroke-linecap="round">
        <path d="M1 4h-.001 V1h2v.001 M1 2.6 h1v.001"/>
      </svg>
    SVG
  end

  # Generate responses for all supported content types
  NucleusRails::ResponseAdapter::CONTENT_TYPES
    .each_key do |k|
    define_method(k) do
      klass = self.class
      content = klass.respond_to?(:"#{k}_content") ? klass.send(:"#{k}_content", self) : "content..."
      build_response(request_format: k, content: content, filename: "#{self.class.to_s.downcase}.#{k}")
    end
  end
end

class TestApplication < Rails::Application
  config.api_only = true
  config.middleware.use ActionDispatch::Cookies
  config.eager_load = :test
  config.hosts << "nucleus"

  NucleusCore.configure do |config|
    config.logger = Rails.logger
  end
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
