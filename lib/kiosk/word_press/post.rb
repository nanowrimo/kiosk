module Kiosk
  module WordPress
    class Post < Resource
      include Searchable::Resource
      include ContentTeaser

      ##############################################################################
      # Content integration
      ##############################################################################
      schema do
        attribute 'title', :string
        attribute 'title_plain', :string
        attribute 'content', :string
        attribute 'excerpt', :string
        attribute 'date', :string
        attribute 'modified', :string
      end

      claims_path_content(:selector => 'a', :pattern => '\d{4}/\d{2}/\d{2}/:slug')

      expires_connection_methods('get_category_posts', 'get_tag_posts', 'get_recent_posts')

      ##############################################################################
      # Indexes
      ##############################################################################
      define_index(:content_post) do
        indexes :title, :content
      end

      ##############################################################################
      # Class methods
      ##############################################################################
      class << self
        def all
          Category.all.inject([]) { |posts,cat| posts += categorized_as(cat) }.uniq { |p| p.id }
        end

        # Fetches posts for the given category.
        #
        def categorized_as(category, params = {})
          category = Kiosk::WordPress::Category.find_by_slug(category) if category.is_a?(String)
          find_by_associated(category, {:count => 100000}.merge(params))
        rescue ResourceNotFound
          []
        end

        # Fetches posts that were created on the given date.
        #
        def created_on(date)
          find(:all, :method => :get_date_posts, :params => [:date => date])
        end

        # Fetches recently made posts.
        #
        def recent
          find(:all, :method => :get_recent_posts)
        end

        # Fetches posts with the given tag.
        #
        def tagged_with(tag)
          find_by_associated(tag)
        end
      end

      ##############################################################################
      # Instance methods
      ##############################################################################

      # Returns the post categories.
      #
      def categories
        attributes[:categories] || []
      end

      # Returns the first category of the post.
      #
      def category
        categories.first
      end

      # The time at which this post was authored.
      #
      def created_at
        attributes[:date].to_time
      end

      # The time at which this post was modified.
      #
      def modified_at
        attributes[:modified].to_time
      end

    end
  end
end
