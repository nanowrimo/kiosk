require 'active_support/concern'

module Kiosk
  # Adds the ability to declare content rewrites in a controller.
  #
  module Controller
    extend ActiveSupport::Concern

    # Declares a rewrite of content nodes that sets the host portion of
    # each node's URI attribute (href or src) to target the configured CDN
    # host.
    #
    def rewrite_cdn_paths_for(resource_model)
      Kiosk.rewriter.add_rewrite(Rewrite.new(:cdn, resource_model))
    end

    # Declares a rewrite of content nodes.
    #
    # Example:
    #
    #   class PostsController
    #     include Kiosk::Controller
    #
    #     before_filter do
    #       rewrite_content_for(Attachment) do |attachment,node|
    #         case node.name
    #         when 'a'
    #           node['title'] = 'Some photo'
    #         when 'img'
    #           node['src'] = attachment_path(attachment.filename)
    #         end
    #       end
    #     end
    #   end
    #
    def rewrite_content_for(resource_model, &blk)
      Kiosk.rewriter.add_rewrite(Rewrite.new(:node, resource_model, &blk))
    end

    # Declares a rewrite of content nodes that sets a new URL any href or src
    # attributes (the first one found, it that order). The given block is
    # passed the instantiated resource and node as its arguments and should
    # return the new value for the node attribute.
    #
    # Example:
    #
    #   class PostsController
    #     include Kiosk::Controller
    #
    #     before_filter do
    #       rewrite_paths_for(Post) { |post| post_path(post.slug) }
    #     end
    #   end
    #
    def rewrite_paths_for(resource_model, &blk)
      Kiosk.rewriter.add_rewrite(Rewrite.new(:path, resource_model, &blk))
    end
  end
end
