module Kiosk
  module Claim
    autoload :NodeClaim, 'kiosk/claim/node_claim'
    autoload :PathClaim, 'kiosk/claim/path_claim'

    class << self
      def new(type = :node, *args, &blk)
        "kiosk/claim/#{type}_claim".classify.constantize.new(*args, &blk)
      end
    end
  end
end
