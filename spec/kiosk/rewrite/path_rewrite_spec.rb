require 'spec_helper'

module Kiosk
  module Rewrite
    describe PathRewrite do
      before(:each) do
        @proc = Proc.new { }
        @node = double('document node')
        @rewrite = PathRewrite.new(@model, &@proc)

        @resource = double('resource')

        @node.stub(:resource).and_return(@resource)
      end

      describe "#evaluate" do
        it("sets the uri attribute and calls the proc") do
          @uri_attribute = double('uri attribute')
          @uri_attribute.should_receive(:content=).with('new value')

          @node.should_receive(:uri_attribute).and_return(@uri_attribute)

          @proc.should_receive(:call).with(@resource, @node).and_return('new value')

          @rewrite.evaluate(@node)
        end
      end
    end
  end
end
