require 'yaml'

# Kiosk provides APIs for integrating WordPress content into a Ruby
# application: a base REST model for retrieving content, a caching layer, and
# a rewriting engine for canonicalizing and contextualizing content elements.
#
module Kiosk
  autoload :BadConfig, 'kiosk/bad_config'
  autoload :ResourceError, 'kiosk/resource_error'
  autoload :ResourceNotFound, 'kiosk/resource_not_found'

  autoload :Cacheable, 'kiosk/cacheable'
  autoload :Cdn, 'kiosk/cdn'
  autoload :Claim, 'kiosk/claim'
  autoload :ClaimedNode, 'kiosk/claimed_node'
  autoload :ContentTeaser, 'kiosk/content_teaser'
  autoload :Controller, 'kiosk/controller'
  autoload :Document, 'kiosk/document'
  autoload :Indexer, 'kiosk/indexer'
  autoload :Localizable, 'kiosk/localizable'
  autoload :Localizer, 'kiosk/localizer'
  autoload :Origin, 'kiosk/origin'
  autoload :ProspectiveNode, 'kiosk/prospective_node'
  autoload :Prospector, 'kiosk/prospector'
  autoload :ResourceController, 'kiosk/resource_controller'
  autoload :ResourceURI, 'kiosk/resource_uri'
  autoload :Rewrite, 'kiosk/rewrite'
  autoload :Rewriter, 'kiosk/rewriter'
  autoload :Searchable, 'kiosk/searchable'
  autoload :WordPress, 'kiosk/word_press'

  ##############################################################################
  # Module methods
  ##############################################################################
  class << self
    # Returns the parsed `config/kiosk.yml`.
    #
    def config
      @config ||= YAML.load(File.open("#{Rails.root}/config/kiosk.yml"))
    end

    # Returns the configuration for the current environment's content origin.
    #
    def origin(env = Rails.env)
      @origins ||= {}

      unless config['origins'] && (config['origins'][env] || config['origins']['default'])
        raise BadConfig, "no origin configured for the `#{env}' or default environment"
      end

      @origins[env] ||= Origin.new(config['origins'][env] || config['origins']['default'])
    end

    # Rewriter object responsible for rewriting resource content.
    #
    def rewriter
      @rewriter ||= Rewriter.new
    end
  end

end
