$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "nucleus-rails"
require "minitest/autorun"

Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |rb| require(rb) }

class Minitest::Spec
  def described_class
    self.class
  end
end