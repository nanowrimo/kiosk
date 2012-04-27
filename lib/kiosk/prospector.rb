require 'active_support/concern'

module Kiosk
  module Prospector
    extend ActiveSupport::Concern

    module ClassMethods
      # Tags portions of any resource content as "belonging" to this resource.
      # For instance, a link to a post could belong to a Post resource. This
      # allows for content to be later rewritten in the controller as deemed
      # necessary. A typical scenario for this requirement might be when URIs
      # within the content need to be targetted to the host app and not a CMS
      # with which you are integrating.
      #
      # For example, links to http://cms.example/post/123 could be tagged
      # by a Post resource and later rewritten by a PostsController to be
      # http://app.example/posts/123.
      #
      # Available options:
      #
      # - +:selector+: The CSS selector used to find content nodes.
      # - +:priority+: Claims with higher priority (a lower value) take
      #                precedence. Symbols +:high+, +:normal+, +:low+ map to
      #                values -9, 0, and 9 respectively.
      # - +:pattern+:  For use with +claims_path_content+. Specifies the
      #                pattern to use when matching a node's URI. See
      #                +ResourceURI#match+ for documentation on pattern syntax.
      #
      # Different types of claims may be supported and are made by calling
      # +claims_<type>_content+. The default is a +Kiosk::Claim::NodeClaim+.
      #
      # Examples:
      #
      #   class Attachment
      #     claims_content(:selector => 'img.attachment') do |node|
      #       (m = node['src'].match(/\d+$)) && { :id => m[1] }
      #     end
      #   end
      #
      # Typically, you'd want to use the extensions of +ProspectiveNode+.
      #
      #   class Post
      #     claims_content(:selector => 'a.post') { |node| node.match_uri 'post/:slug' }
      #   end
      #
      # A +PathClaim+ is also available that simplified this pattern. See
      # +ResourceURI#match+ for documentation regarding the URI pattern.
      #
      #   class Post
      #     claims_path_content(:selector => 'a.post', :pattern => 'post/:slug')
      #   end
      #
      def claims_content(options = {}, &parser)
        claims_x_content(:node, options, &parser)
      end

      # Handles calls to +claims_<type>_content+. See +method_missing+.
      #
      def claims_x_content(type, options = {}, &parser)
        Kiosk.rewriter.add_claim(Kiosk::Claim.new(type, self, options, &parser), options)
      end

      # Implements +claims_<type>_content+ methods. See +claims_x_content+.
      #
      def method_missing(name, *args, &blk)
        case name.to_s
        when /^claims_(\w+)_content$/
          claims_x_content($1.to_sym, *args, &blk)
        else
          super
        end
      end
    end
  end
end
