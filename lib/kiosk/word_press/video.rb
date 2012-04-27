module Kiosk
  module WordPress
    class Video < Resource
      schema do
        attribute 'id', :string
        attribute 'slug', :string
        attribute 'classid', :string
      end

      claims_content(:selector => 'object') do |object|
        if object['id'] && (match = object['id'].match(/^viddler(?:player)?-(\w+)/))
          {:slug => object['id'], :classid => object['classid']}
        end
      end

      # Returns the video ID, which is either an explicitly set attribute or the
      # trailing string identifier from the slug (following the last "-").
      #
      def id
        attributes[:id] || (attributes[:slug] && attributes[:slug].match(/-(\w+)$/)[1])
      end

      # Returns the path to the "thumbnail" version of the movie.
      #
      def thumbnail_url
        "http://www.viddler.com/simple/#{id}/"
      end

      # Returns the path to the "full" version of the movie.
      #
      def url
        "http://www.viddler.com/player/#{id}/"
      end
    end
  end
end
