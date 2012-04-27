module Kiosk
  module Rewrite
    class CdnRewrite < NodeRewrite
      def evaluate(node)
        Kiosk.origin.cdn.rewrite_node(node)
      end
    end
  end
end
