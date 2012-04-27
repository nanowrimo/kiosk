# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

require 'rubygems'
require 'bundler'

Bundler.require(:default, :development)

require 'kiosk'

# Mock Rails
module Rails
  def self.env
    'test'
  end

  def self.root
    File.expand_path(__FILE__, '../dummy')
  end
end

RSpec.configure do |config|
  config.include RSpec::Matchers

  config.mock_with :rspec
end
