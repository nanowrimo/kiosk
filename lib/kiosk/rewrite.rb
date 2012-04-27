module Kiosk
  module Rewrite
    autoload :CdnRewrite, 'kiosk/rewrite/cdn_rewrite'
    autoload :NodeRewrite, 'kiosk/rewrite/node_rewrite'
    autoload :PathRewrite, 'kiosk/rewrite/path_rewrite'

    class << self
      def new(type = :node, *args, &blk)
        "kiosk/rewrite/#{type}_rewrite".classify.constantize.new(*args, &blk)
      end
    end
  end
end
