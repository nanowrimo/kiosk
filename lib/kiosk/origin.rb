module Kiosk
  class Origin
    attr_reader :site, :indexer, :default_locale, :cdn

    def initialize(config)
      @site = (config['site'] || '').sub(/\/+$/, '') + '/'
      @indexer = Kiosk::Indexer::Adapter.new(config['indexer']) if config['indexer']
      @default_locale = config['default_locale']
      @cdn = Kiosk::Cdn.new(config['cdn'] || {})
    end

    def searcher
      @indexer
    end

    def site_uri
      URI.parse(site)
    end
  end
end
