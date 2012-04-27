module Kiosk
  class Cdn
    attr_reader :host

    def initialize(config = {})
      @host = config['host']
    end

    def configured?
      @host
    end

    def rewrite_node(node)
      if configured?
        node.uri_attribute.content = rewrite_uri(URI.parse(node.uri_attribute.content)).to_s
      end
    rescue URI::InvalidURIError
      nil
    end

    def rewrite_uri(uri)
      if configured?
        uri.host = host
      end
      uri
    end
  end
end
