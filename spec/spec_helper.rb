require 'simplecov'
require 'simplecov-cobertura'
require 'simplecov-html'

if ENV['COVERAGE']
  SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::CoberturaFormatter,
    SimpleCov::Formatter::HTMLFormatter
  ])

  SimpleCov.start do
    enable_coverage :branch
    primary_coverage :branch
  end
end

require "shopify-lita-slack"
require "lita/rspec"

Lita.version_3_compatibility_mode = false

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end

Lita.configure do |config|
  config.redis[:host] = ENV["REDIS_HOST"]
  config.redis[:port] = ENV["REDIS_PORT"]
end