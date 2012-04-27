module Kiosk
  module Rewrite
    class PathRewrite < NodeRewrite
      def evaluate(node)
        node.uri_attribute.content = @proc.call(node.resource,node)
      rescue ActionController::RoutingError => e
      end
    end
  end
end
