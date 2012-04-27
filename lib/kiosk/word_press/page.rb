module Kiosk
  module WordPress
    class Page < Resource
      include Searchable::Resource

      ##############################################################################
      # Content integration
      ##############################################################################
      schema do
        attribute 'title', :string
        attribute 'title_plain', :string
        attribute 'content', :string
        attribute 'excerpt', :string
      end

      claims_path_content(:selector => 'a',
                          :pattern => ':slug',
                          :shims => {:slug => /[^\?]+/},
                          :priority => :low)

      ##############################################################################
      # Indexes
      ##############################################################################
      define_index(:content_page) do
        indexes :title, :content
      end

      ##############################################################################
      # Instance methods
      ##############################################################################

      # Returns the leading portion of the slug.
      #
      def section
        (s = slug.to_s).empty? ? nil : s.split('/').first
      end

      # Returns the full page slug. This differs in cases where the page is a
      # child of another in the hierarchy. E.g. where a parent page has slug
      # 'p1' and the child page has slug 'c1', 'p1/c1' would be returned, not
      # simply 'c1'.
      #
      def slug
        begin
          #parse the url
          uri = URI.parse(url)
          #get the route from the original site uri
          route = uri.route_from(Content.origin.site_uri)
          #return just the path
          route.path
        rescue
          attributes[:slug]
        end
      end
    end
  end
end
