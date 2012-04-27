require 'spec_helper'

module Kiosk
  module Rewrite
    describe NodeRewrite do
      before(:each) do
        @model = Class.new
        @proc = Proc.new { }

        @node = double('document node')
        @node.extend(ClaimedNode)
        @node.stub(:resource).and_return(@model.new)

        @rewrite = NodeRewrite.new(@model, &@proc)
      end

      describe "#matches?" do
        subject { @rewrite.matches?(@node) }

        context "where the node resource is an instance of the model" do
          it("is true") { should be_true }
        end

        context "where the node resource is not an instance of the model" do
          before(:each) { @node.stub(:resource).and_return(double('something else')) }
          it("is false") { should be_false }
        end
      end

      describe "#evaluate" do
        it("calls the proc") { @proc.should_receive(:call).once; @rewrite.evaluate(@node) }
      end
    end
  end
end
