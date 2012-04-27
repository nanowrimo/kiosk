module Kiosk
  module WordPress
    class Category < Resource
      schema do
        attribute 'title', :string
      end

      # Retrieves a specific category by its slug. This can't be done directly
      # through the WordPress JSON API, so all categories are traversed instead.
      #
      def self.find_by_slug(slug)
        category = all.detect { |category| category.slug == slug }
        raise ResourceNotFound.new("unknown category `#{slug}'") unless category
        category
      end
    end
  end
end
