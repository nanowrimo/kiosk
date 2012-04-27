module Kiosk
  module ClaimedNode
    attr_accessor :resource

    def uri_attribute
      (name = ['href', 'src'].detect { |attr| attributes.key?(attr) }) && attributes[name]
    end
  end
end
