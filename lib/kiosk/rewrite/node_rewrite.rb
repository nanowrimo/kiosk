module Kiosk
  module Rewrite
    class NodeRewrite
      def initialize(model, &blk)
        @model = model
        @proc = blk
      end

      def matches?(node)
        node.is_a?(ClaimedNode) && @model.ancestors.include?(node.resource.class)
      end

      def evaluate(node)
        @proc.call(node.resource, node)
      end
    end
  end
end
