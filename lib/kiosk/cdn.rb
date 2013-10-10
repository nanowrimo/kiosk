module Kiosk
  class Cdn
    attr_reader :host

    def initialize(config = {})
      @host = config['host']

      unless @host.nil? || @host.empty?
        @uri = URI.parse(@host)
        @host_only = @uri.scheme.nil? && @uri.host.nil?
      end
    end

    def configured?
      !@uri.nil?
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
        if @host_only
          uri.host = @host
        else
          uri.scheme = @uri.scheme
          uri.host = @uri.host
          uri.path = "#{@uri.path.sub(/\/$/, '')}#{uri.path}" unless @uri.path.empty? || @uri.path == '/'
        end
      end
      uri
    end
  end
end
