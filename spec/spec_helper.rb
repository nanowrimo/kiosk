# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

require 'rubygems'
require 'bundler'

Bundler.require(:default, :development)

require 'kiosk'

# Mock Rails
module Rails
  def self.application
  end

  def self.cache
  end

  def self.env
    'test'
  end

  def self.root
    File.expand_path('../dummy', __FILE__)
  end
end

RSpec.configure do |config|
  config.include RSpec::Matchers

  config.mock_with :rspec
end
