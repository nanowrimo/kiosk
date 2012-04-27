require 'spec_helper'

module Kiosk
  module Claim
    describe NodeClaim do
      before(:each) do
        @document = Document.parse(<<-end_document)
          <a id="l1" class="post" href="http://some.example/site/post/123">post</a>
          <a id="l2" class="post" href="http://other.example/site/post/123">external post</a>
        end_document

        @origin = Origin.new({'site' => 'http://some.example/site/'})
        Kiosk.stub(:origin).and_return(@origin)

        @model = Class.new(Kiosk::Resource)
      end

      describe "#stake!" do
        context "with a matching selector and block parser" do
          before(:each) do
            @claim = NodeClaim.new(@model, :selector => 'a.post') do |node|
              {:name => 'value'} if node['id'] == 'l1'
            end
          end

          it("stakes its claim for matched nodes") do
            @dummy = double('dummy')
            @dummy.should_receive(:staked!).once
            @claim.stake!(@document) { |node| @dummy.staked!; node['id'].should == 'l1' }
          end

          it("sets an instance of the model") do
            @model.should_receive(:new).once.with({:name => 'value'})
            @claim.stake!(@document)
          end
        end

        context "where the node has already been staked" do
          before(:each) do
            @claim1 = NodeClaim.new(@model, :selector => '#l1') { |n| {:id => 1} }
            @claim2 = NodeClaim.new(@model, :selector => '#l1') { |n| {:id => 1} }

            @dummy1 = double('dummy')
            @dummy1.should_receive(:staked!).once

            @claim1.stake!(@document) { |node| @dummy1.staked! }
          end

          it("should not re-stake") do
            @dummy2 = double('dummy')
            @dummy2.should_not_receive(:staked!)

            @claim2.stake!(@document) { |node| @dummy2.staked! }
          end
        end
      end
    end
  end
end
