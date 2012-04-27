module Kiosk
  module Indexer
    module Adapter
      autoload :Base, 'kiosk/indexer/adapter/base'
      autoload :ThinkingSphinxAdapter, 'kiosk/indexer/adapter/thinking_sphinx_adapter'

      class << self
        def new(type = :thinking_sphinx, *args)
          "kiosk/indexer/adapter/#{type}_adapter".classify.constantize.new(*args)
        end
      end
    end
  end
end
