require 'active_support/core_ext/string'

module Kiosk
  module ContentTeaser
    # Returns a teaser of the content with roughly the given length.
    #
    # The content is parsed as an HTML fragment and only text nodes are
    # considered to have length in this context. As a result, the returned
    # string will not have a length matching the given +horizon+ exactly, but
    # should render as such.
    #
    def teaser(horizon, options = {})
      if doc = content_document

        # Traverse all text nodes until we reach the limit
        length = 0

        # Find the boundary node, where the text length crosses the horizon
        node = doc.xpath('descendant::text()').detect do |n|
          (length += n.content.length) >= horizon
        end

        if node
          # Truncate the content of the boundary text node
          node.content = node.content.truncate(node.content.length - (length - horizon), options)

          # Remove all following nodes from the document
          # Note that this mark-and-sweep method is due to the catch 22 of
          # relative DOM traversal (next, parent, etc.) and node removal.
          nodes_to_remove = []
          nodes_to_remove << node while node = (node.next || (node.parent && node.parent.next))
          nodes_to_remove.each { |n| n.remove if n.parent }
        end

        doc.to_html
      else
        ""
      end
    end
  end
end
