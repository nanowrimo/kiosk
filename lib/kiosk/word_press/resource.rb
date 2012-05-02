require 'active_resource'

# Proxy for content resources.
#
module Kiosk
  module WordPress
    class Resource < ::ActiveResource::Base
      include Cacheable::Resource
      include Localizable::Resource
      include Prospector

      ##############################################################################
      # ActiveResource config
      ##############################################################################
      self.site = Kiosk.origin.site
      self.format = :json

      schema do
        attribute 'slug', :string
      end

      ##############################################################################
      # Caching
      ##############################################################################
      cached_expire_in { |resource| resource['status'] == 'error' ? 30.minutes : 1.day }

      ##############################################################################
      # Class methods
      ##############################################################################
      class << self
        # Returns all instances of the resource.
        #
        def all
          find(:all)
        end

        # Reimplements the +ActiveResource+ path constructor to work with the
        # WordPress JSON-API plugin.
        #
        def element_path(id, prefix_options = {}, query_options = nil)
          "#{api_path_to("get_#{element_name}")}#{query_string({:id => id}.merge(query_options || {}))}"
        end

        def element_path_by_slug(slug, prefix_options = {}, query_options = nil)
          "#{api_path_to("get_#{element_name}")}#{query_string({:slug => slug}.merge(query_options || {}))}"
        end

        # Adds functionality to the +ActiveResource.find+ method to allow for
        # specifying the WordPress JSON API method that should be used. This
        # simplifies definition of scopes in derived models.
        #
        def find(*arguments)
          scope   = arguments.slice!(0)
          options = arguments.slice!(0) || {}

          if options.key?(:method)
            options[:from] = api_path_to(options[:method])
            options.delete(:method)
          end

          super(scope, options)
        end

        # Finds all resources by the given related resource.
        #
        # Example:
        #
        #   Post.find_by_associated(category)
        #
        # Is the same as invoking:
        #
        #   Post.find(:all, :method => "get_category_posts", :params => {:id => category.id})
        #
        def find_by_associated(resource, params = {})
          find(:all,
               :method => "get_#{resource.class.element_name}_#{element_name.pluralize}",
               :params => params.merge({:id => resource.id}))
        end

        # Finds the resource by the given slug.
        #
        def find_by_slug(slug)
          find(:one, :method => "get_#{element_name}", :params => {:slug => slug})
        end

        # Reimplements the +ActiveResource+ path constructor to work with the
        # WordPress JSON-API plugin.
        #
        def collection_path(prefix_options = {}, query_options = nil)
          "#{api_path_to("get_#{element_name}_index")}#{query_string(query_options)}"
        end

        # Reimplements the +ActiveResource+ method to check for bad responses
        # before instantiating a collection.
        #
        def instantiate_collection(collection, prefix_options = {})
          super(normalize_response(collection, true), prefix_options)
        end

        # Reimplements the +ActiveResource+ method to check for bad responses
        # before instantiating an object.
        #
        def instantiate_record(record, prefix_options = {})
          super(normalize_response(record), prefix_options)
        end

        # Executes the given block within a scope where all requests for this
        # content resource are appended with the given parameters.
        #
        #   class Post < Resource; end
        #
        #   Post.with_parameters(:language => 'en') do
        #     english_posts = Post.find(:all)
        #     english_pages = Page.find(:all)
        #   end
        #
        # Scopes can be nested.
        #
        #   Post.with_parameters(:language => 'es') do
        #     Post.with_parameters(:recent => true) do
        #       recent_spanish_posts = Post.find(:all)
        #     end
        #   end
        #
        # Scopes are inherited.
        #
        #   Resource.with_parameters(:language => 'fr') do
        #     french_posts = Post.find(:all)
        #   end
        #
        # However, nesting is still respected.
        #
        #   Resource.with_parameters(:language => 'fr') do
        #     Post.with_parameters(:language => 'en') do
        #       english_posts = Post.find(:all)
        #     end
        #   end
        #
        # Even with this nesting inverted.
        #
        #   Post.with_parameters(:language => 'fr') do
        #     Resource.with_parameters(:language => 'en') do
        #       english_posts = Post.find(:all)
        #     end
        #   end
        #
        def with_parameters(params = {})
          push_to_query_scope_stack(params)

          begin
            yield
          ensure
            pop_from_query_scope_stack
          end
        end

        protected

        # Returns the path to the given method of the WordPress API.
        #
        def api_path_to(method)
          "#{site.path}api/#{method}/"
        end

        # Checks the given response for errors and normalizes its structure. A
        # response from the API includes an envelope, which must be checked for
        # the response status ("ok" or "error"). If an error is found, an
        # exception is raised.
        #
        def normalize_response(response, collection = false)
          response = case response['status']
                     when 'ok'
                       response[collection ? element_name.pluralize : element_name]
                     when 'error'
                       raise_error(response['error'])
                     else
                       # This isn't a response envelope. Just let it pass through.
                       response
                     end

          camelcase_keys(response)
        end

        # Reimplements the parent method to include parameters of the current
        # query scope. See +with_parameters+.
        #
        def query_string(options)
          scoped_options = my_query_scope_stack.inject({}) do |scoped_options,(klass,opt_stack)|
            if self.ancestors.include?(klass)
              scoped_options = opt_stack.reduce(scoped_options) do |scoped_options,opts|
                scoped_options.merge(opts)
              end
            else
              scoped_options
            end
          end

          super(scoped_options.merge(options))
        end

        # Handles errors returned by the WordPress JSON API.
        #
        def raise_error(error)
          case error
          when 'Not found.'
            raise Kiosk::ResourceNotFound.new(error)
          when /Un?known method '(\w+)'/ # note the possibility of a spelling error
            raise NotImplementedError.new(error)
          else
            raise Kiosk::ResourceError.new(error)
          end
        end

        private

        mattr_accessor :query_scope_stack

        # Filters and sorts the query-scope stack so that only scopes relevant
        # to this class are applied and are applied in order from furthest
        # ancestor to nearest.
        #
        def my_query_scope_stack
          if query_scope_stack
            Hash[query_scope_stack.select do |klass,stack|
              self.ancestors.include?(klass)
            end.sort_by do |klass,stack|
              self.ancestors.index(klass) * -1
            end]
          else
            {}
          end
        end

        def push_to_query_scope_stack(params)
          self.query_scope_stack ||= {}
          self.query_scope_stack[self] ||= []

          # Append stacks for this class and all descendent classes.
          query_scope_stack.each_key do |klass|
            query_scope_stack[klass].push(params) if klass.ancestors.include?(self)
          end
        end

        def pop_from_query_scope_stack
          # Pop stacks for this class and all descendent classes.
          query_scope_stack.each_key do |klass|
            query_scope_stack[klass].pop if klass.ancestors.include?(self)
          end
        end

        # Recursively changes the keys of the given hash (or array of hashes)
        # to camelcase.
        #
        def camelcase_keys(obj)
          case obj
          when Hash
            obj.inject({}) { |hash,(k,v)| hash[k.to_s.underscore] = camelcase_keys(v); hash }
          when Array
            obj.map { |v| camelcase_keys(v) }
          else
            obj
          end
        end
      end

      ##############################################################################
      # Instance methods
      ##############################################################################

      # Returns the rewritten resource content. See +raw_content+ for untouched
      # content.
      #
      def content
        @content ||= raw_content && Kiosk.rewriter.rewrite(raw_content)
      end

      # Returns the rewritten resource content as a +Document+.
      #
      def content_document
        raw_content && Kiosk.rewriter.rewrite_to_document(raw_content)
      end

      # Returns the rewritten resource excerpt. See +raw_excerpt+ for untouched
      # content.
      #
      def excerpt
        @excerpt ||= raw_excerpt && Kiosk.rewriter.rewrite(raw_excerpt)
      end

      # Destroying is not supported.
      #
      def destroy
        raise NotImplementedError
      end

      # Returns the resource content, untouched by the content rewriter.
      #
      def raw_content
        attributes[:content]
      end

      # Returns the resource excerpt, untouched by the content rewriter.
      #
      def raw_excerpt
        attributes[:excerpt]
      end

      # Saving is not supported.
      #
      def save
        raise NotImplementedError
      end

      # Returns the value used in constructing a URL to this object.
      #
      def to_param
        attributes[:slug] || attributes[:id]
      end
    end
  end
end
