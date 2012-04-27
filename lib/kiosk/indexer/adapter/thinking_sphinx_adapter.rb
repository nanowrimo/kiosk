require 'active_support/concern'

module Kiosk::Indexer::Adapter
  class ThinkingSphinxAdapter < Base

    def index(name, io = STDOUT)
      index = nil

      ThinkingSphinx.context.indexed_resources.each do |res|
        if i = res.constantize.sphinx_indexes.detect { |index| index.name == name }
          index = i
        end
      end

      index.write_xml_to(io) if index
    end

    module Resource
      extend ActiveSupport::Concern

      included do
        # Mixin implementation for Thinking Sphinx
        unless ThinkingSphinx.context.is_a?(Context)
          ThinkingSphinx.context.extend(Context)
        end

        unless ThinkingSphinx::Configuration.instance.configuration.is_a?(Configuration)
          ThinkingSphinx::Configuration.instance.configuration.extend(Configuration)
        end
      end

      module ClassMethods
        attr_accessor :sphinx_indexes

        def define_index(name, &blk)
          self.sphinx_indexes ||= []

          ThinkingSphinx.context.add_indexed_resource self

          index = Index.new(self, name.to_s)
          index.instance_exec(&blk)

          sphinx_indexes << index unless sphinx_indexes.any? { |i| i.name == index.name }
        end

        def search(*args)
          options = args.extract_options!
          query = args.first

          Search.new(query, options).execute_for(self)
        end

        def sphinx_index_names
          sphinx_indexes.collect { |index| index.name }
        end

        def to_riddle
          if sphinx_indexes
            sphinx_indexes.collect { |index| index.to_riddle }.flatten
          else
            []
          end
        end
      end
    end

    class Search
      attr_reader :query, :options

      def initialize(query, options = {})
        @query = query
        @options = {:comment => ''}.merge(options)
        @proxy = SearchProxy.new(@options)
      end

      def execute_for(model)
        query = @proxy.star_query(@query)
        using_options(@options) do
          SearchResults.new(client.query(query, index_names_for(model), @options[:comment]), model, @options)
        end
      end

      private

      def using_options(options)
        original_options = {}

        options.each do |name,value|
          if client.respond_to?("#{name}=")
            original_options[name] = value
            client.send("#{name}=", value)
          end
        end

        result = yield

        original_options.each do |name,value|
          client.send("#{name}=", value)
        end

        result
      end

      def index_names_for(model)
        model.sphinx_index_names.join(',')
      end

      def client
        ThinkingSphinx::Configuration.instance.client
      end
    end

    # Used to steal methods from +ThinkingSphinx::Search+.
    #
    class SearchProxy < ThinkingSphinx::Search
      def initialize(options = {})
        @options = options
      end

      def star_query(query)
        @options[:star] ? super(query) : query
      end
    end

    class SearchResults < Array
      attr_reader :results

      def initialize(sphinx_results, model, search_options)
        @model = model
        @results = sphinx_results
        @options = search_options

        populate if @results && @results[:matches]
      end

      def current_page
        @options[:page].blank? ? 1 : @options[:page].to_i
      end

      def per_page
        (@options[:per_page] || 20).to_i
      end

      def total_entries
        @results[:total_found] || 0
      end

      def total_pages
        (@results[:total] / per_page.to_f).ceil
      end

      private

      def populate
        replace(@results[:matches].collect { |match|
          begin
            @model.find(match[:doc])
          rescue Kiosk::ResourceNotFound => e
            @model.new
          end
        })
      end
    end

    module Context
      attr_reader :indexed_resources

      def add_indexed_resource(resource)
        resource = resource.name if resource.is_a?(Class)

        @indexed_resources ||= []
        @indexed_resources << resource unless @indexed_resources.include?(resource)
      end
    end

    module Configuration
      # Reimplement +Riddle::Configuration#render+ to include our own indexes
      # in the config before it's rendered.
      #
      def render
        ThinkingSphinx.context.indexed_resources.each do |resource|
          resource.constantize.to_riddle.each do |index|
            indices << index unless indices.any? { |i| i.name == index.name }
          end
        end

        super
      end
    end

    class Index
      attr_reader :mode, :name

      def initialize(model, name)
        @model = model
        @name = name

        @fields = []
      end

      def indexes(*fields)
        @fields += fields.collect { |field| Field.new(field) }
      end

      def config
        @config ||= ThinkingSphinx::Configuration.instance
      end

      def to_riddle
        index = Riddle::Configuration::Index.new(@name)
        index.path = File.join(config.searchd_file_path, index.name)

        config.index_options.each do |key,value|
          method = "#{key}=".to_sym
          index.send(method, value) if index.respond_to?(method)
        end

        source = Riddle::Configuration::XMLSource.new("#{@name}_source", :xmlpipe2)
        source.xmlpipe_command = rake("kiosk:index[#{name}]")

        index.sources << source

        [index]
      end

      def write_xml_to(io)
        xm = Builder::XmlMarkup.new(:target => io)

        xm.instruct!
        xm.sphinx :docset, 'xmlns:sphinx' => 'http://sphinxsearch.com' do
          xm.sphinx :schema do
            @fields.each { |field| field.to_xml(xm) }
          end

          @model.all.each do |resource|
            xm.sphinx :document, :id => resource.id do
              @fields.each do |field|
                xm.send(field.name, resource.send(field.name))
              end
            end
          end
        end
      end

      private

      def rake(task)
        "#{Gem.bin_path('rake', 'rake')} --silent -f #{Rails.root}/Rakefile #{task}"
      end
    end

    class Field
      attr_reader :name

      def initialize(name)
        name = name.to_s
        raise ArgumentError.new('invalid name') unless name =~ /^\w+$/
        @name = name
      end

      def to_xml(builder)
        builder.sphinx :field, :name => name
      end
    end
  end
end
