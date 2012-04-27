module Kiosk
  module Claim
    class NodeClaim
      attr_reader :model, :selector, :parser

      def initialize(model, options = {}, &parser)
        raise ArgumentError.new('no selector given') unless options[:selector]
        raise ArgumentError.new('no block provided') unless block_given?

        @model = model
        @selector = options[:selector]
        @parser = parser
      end

      # Stakes the claim over the given content document and yields the provided
      # block for each match. The block is passed each node, which has been
      # extended with implementation in +ClaimedNode+.
      #
      def stake!(document)
        select_from(document).each do |node|
          unless node.is_a?(ClaimedNode)
            node.extend(ProspectiveNode) unless node.is_a?(ProspectiveNode)

            # If the parser finds anything in the selected node, stake the claim
            if attributes = parser.call(node)
              node.extend(ClaimedNode)
              node.resource = @model.new(attributes)

              yield node if block_given?
            end
          end
        end
      end

      protected

      # Implements the selection of nodes to process when staking the claim.
      #
      def select_from(document)
        document.css(selector)
      end
    end
  end
end
