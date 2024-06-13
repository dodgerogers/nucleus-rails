$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "nucleus_rails"
require "minitest/autorun"
require "minitest/reporters"
require "sidekiq"
require "sidekiq/testing"

Minitest::Reporters.use!

Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |rb| require(rb) }
