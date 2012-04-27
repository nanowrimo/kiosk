require 'active_support/concern'

module Kiosk
  # Provides indexing of content resources for supported search providers. As
  # of now, only Thinking Sphinx/Sphinx is provided for.
  #
  module Searchable::Resource
    extend ActiveSupport::Concern

    included do
      raise BadConfig.new('you must configure an indexer') unless Kiosk.origin.indexer
      Kiosk.origin.indexer.extend_model(self)
    end
  end
end
