module Kiosk
  module ProspectiveNode
    # Attempts to match the given pattern against the resource URI.
    #
    def match_uri(pattern, shim_patterns = {})
      resource_uri.match(pattern, shim_patterns)
    rescue URI::BadURIError, URI::InvalidURIError
      nil
    end

    # Returns either the nodes +href+ or +src+ attribute as a parsed
    # +ResourceURI+.
    #
    def resource_uri
      ResourceURI.parse(self['href'] || self['src'] || '')
    end
  end
end
