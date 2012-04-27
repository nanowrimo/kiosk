require 'spec_helper'

module Kiosk
  module Claim
    describe PathClaim do
      before(:each) do
        @document = Document.parse(<<-end_document)
          <a id="l1" class="post" href="http://some.example/site/post/123">post</a>
          <a id="l2" class="post" href="http://other.example/site/post/123">external post</a>
        end_document

        @origin = Origin.new({'site' => 'http://some.example/site/'})
        Kiosk.stub(:origin).and_return(@origin)

        @model = Class.new(WordPress::Resource)
      end

      describe "#stake!" do
        context "with a matching selector and URI pattern" do
          before(:each) do
            @claim = PathClaim.new(@model, :selector => 'a.post', :pattern => 'post/:id')
          end

          it("stakes its claim for matched nodes") do
            @dummy = double('dummy')
            @dummy.should_receive(:staked!).once
            @claim.stake!(@document) { |node| @dummy.staked! }
          end
        end
      end
    end
  end
end
