require 'spec_helper'

require 'nokogiri'

module Kiosk
  describe ClaimedNode do
    before(:each) do
      @node = Nokogiri::XML::Node.new('a', Nokogiri::XML::Document.new)
      @node['href'] = 'http://some.example'
      @node.extend(ClaimedNode)
    end

    describe "#uri_attribute" do
      subject { @node.uri_attribute }

      it("returns an xml attribute") { should be_a(Nokogiri::XML::Attr) }
    end
  end
end
