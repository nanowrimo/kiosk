module Kiosk
  module Claim
    class PathClaim < NodeClaim
      def initialize(type, options = {}, &parser)
        raise ArgumentError.new('no path pattern given') unless options[:pattern]

        super(type, options) { |node| node.match_uri(options[:pattern], options[:shims]) }
      end
    end
  end
end
