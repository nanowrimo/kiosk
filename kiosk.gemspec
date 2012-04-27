$:.push File.expand_path('../lib', __FILE__)

require 'kiosk/version'

Gem::Specification.new do |s|
  s.name = 'kiosk'
  s.summary = 'Simple WordPress integration for Ruby applications.'
  s.description = (<<-end_).split.join(' ')
    Kiosk provides APIs for integrating WordPress content into a Ruby
    application: a base REST model for retrieving content, a caching layer,
    and a rewriting engine for canonicalizing and contextualizing content
    elements.
  end_

  s.platform = Gem::Platform::RUBY
  s.authors = ['Daniel Duvall']
  s.email = ['dan@mutual.io']

  s.files = Dir['{lib}/**/*'] + ['MIT-LICENSE', 'Rakefile', 'Gemfile', 'README.rdoc']
  s.version = Kiosk::VERSION

  s.require_paths = ['lib']

  s.add_runtime_dependency 'nokogiri', '~> 1.5'
  s.add_runtime_dependency 'rails', '~> 3.0.10'

  s.add_development_dependency 'rspec', '~> 2.5'
  s.add_development_dependency 'shoulda'
end
