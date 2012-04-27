module Kiosk
  module ResourceURI
    DEFAULT_SHIM_PATTERN = /[^\/\?]+/

    class << self
      def parse(uri_string)
        (uri = URI.parse(uri_string)) && uri.extend(InstanceMethods)
      end
    end

    module InstanceMethods
      # Matches the relative part of the URI path with the given pattern and
      # returns a hash of parsed attributes constructed from the match. The
      # pattern for each shim can be provided as a hash.
      #
      # Examples:
      #
      #   uri = ResourceURI.parse('http://some.example/site/post/some-slug')
      #
      #   uri.match('post/:slug')
      #   # => { :slug => 'some-slug' }
      #
      #   uri.match('post/:id', :id => /\d+/)
      #   # => nil
      #
      # Tokens in the pattern starting with '!' are not captured. They can be
      # used to represent portions of the path by name that are purely for
      # readability.
      #
      def match(pattern, shim_patterns = nil)
        shims = []
        shim_patterns ||= {}

        re_pattern = pattern.gsub(/!(\w+)/, DEFAULT_SHIM_PATTERN.to_s)
        re_pattern = re_pattern.gsub(/:(\w+)/) do |s|
          shims << (shim = $1.to_sym)
          '(' + (shim_patterns[shim] || DEFAULT_SHIM_PATTERN).to_s + ')'
        end

        re = Regexp.new('^' + re_pattern + '.*$')

        # Match against the part of the URI path that follows the content origin
        # site path. If the resulting route contains no host and is relative,
        # the URI is within our content origin.
        if route = route_from(Kiosk.origin.site)
          if route.host.nil? and route.relative?
            route.path.match(re) do |matches|
              attributes = {}
              shims.each_with_index { |shim,i| attributes[shim] = matches[i + 1] }
              attributes
            end
          end
        end
      end

      # Reimplements parent method so as to further qualify routes that are
      # relative but outside the base origin site path (routes that resolve to
      # '../some/external/path').
      #
      def route_from(uri)
        uri = URI.parse(uri) unless uri.is_a?(URI::Generic)

        # allow a route from http to https to be relative if the host is the
        # same
        if (uri.host == self.host) and (uri.scheme == 'http' and self.scheme == 'https')
          self.scheme = 'http'
          self.port = uri.port
        end

        route = super(uri)

        if route.relative? && route.path['../']
          new_uri = uri.clone
          new_uri.path = File.expand_path(route.path, uri.path)
          new_uri
        else
          route
        end
      end
    end
  end
end
