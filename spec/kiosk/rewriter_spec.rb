require 'spec_helper'

module Kiosk
  describe Rewriter do

    ##############################################################################
    # Instance methods
    ##############################################################################
    context "instance method " do
      before(:each) do
        @content = <<-end_content
          <p>
            Link to a <a class="post" href="http://some.example/site/post/123">post</a>.
          </p>
          <p>
            Link to a <a class="page" href="http://some.example/site/page-name">page</a>.
            <img src="http://some.example/site/file/name.png"/>
            Link to a <a href="http://some.example/site/page/456">page</a>.
          </p>
        end_content

        @origin = Origin.new({'site' => 'http://some.example/site/'})
        Kiosk.stub(:origin).and_return(@origin)

        @post_model = Class.new(WordPress::Resource)
        @page_model = Class.new(WordPress::Resource)
        @att_model = Class.new(WordPress::Resource)

        @rewriter = Rewriter.new
      end

      describe "#add_claim" do
        context "given no priority" do
          before(:each) do
            @rewriter.add_claim(@claim = double('claim'))
          end

          it("adds the claim with priority 0") do
            @rewriter.instance_variable_get(:@claims).should == {0 => [@claim]}
          end
        end

        context "given a priority" do
          before(:each) do
            @rewriter.add_claim(@claim = double('claim'), :priority => 1)
          end

          it("adds the claim with that priority") do
            @rewriter.instance_variable_get(:@claims).should == {1 => [@claim]}
          end
        end

        context "given a priority by name" do
          before(:each) do
            @rewriter.add_claim(@claim = double('claim'), :priority => :high)
          end

          it("adds the claim with the corresponding numerical priority") do
            @rewriter.instance_variable_get(:@claims).should == {-9 => [@claim]}
          end
        end
      end

      describe "#rewrite" do
        before(:each) do
          @claim1 = Claim.new(:path, @post_model, :selector => 'a.post', :pattern => 'post/:id')
          @claim2 = Claim.new(:path, @page_model, :selector => 'a', :pattern => ':slug')
          @claim3 = Claim.new(:node, @page_model, :selector => 'a.page') do |n|
            n.match_uri('page/:id')
          end
          @claim4 = Claim.new(:path, @att_model, :selector => 'img', :pattern => 'file/:filename')

          @rewriter.add_claim(@claim1)
          @rewriter.add_claim(@claim2, :priority => :low)
          @rewriter.add_claim(@claim3)
          @rewriter.add_claim(@claim4, :priority => :high)

          @rewrite1 = Rewrite.new(:path, @post_model) { |post| "post_url" }
          @rewrite2 = Rewrite.new(:path, @page_model) { |page| 'page_url' }
          @rewrite3 = Rewrite.new(:node, @att_model) { |attachment,node| node.name = 'p' }

          @rewriter.instance_variable_set(:@rewrites, [@rewrite1, @rewrite2, @rewrite3])
        end

        it("iterates over all claims") do
          @claim1.parser.should_receive(:call).once
          @claim2.parser.should_receive(:call).exactly(3).times
          @claim3.parser.should_receive(:call).once
          @claim4.parser.should_receive(:call).once

          @rewriter.rewrite(@content)
        end

        it("evaulates all matching rewrites") do
          @rewrite1.should_receive(:evaluate).once
          @rewrite2.should_receive(:evaluate).exactly(2).times
          @rewrite3.should_receive(:evaluate).once

          @rewriter.rewrite(@content)
        end

        it("correctly rewrites the content") do
          @content = (<<-end_content).rstrip
            <p>
              Link to a <a class="post" href="http://some.example/site/post/123">post</a>.
            </p>
            <p>
              Link to a <a class="page" href="http://some.example/site/page/321">page</a>.
              <img src="http://some.example/site/file/name.png"/>
              Link to a <a href="http://some.example/site/page/456">page</a>.
            </p>
          end_content

          @rewriter.rewrite(@content).should == (<<-end_content).rstrip
            <p>
              Link to a <a class="post" href="post_url">post</a>.
            </p>
            <p>
              Link to a <a class="page" href="page_url">page</a>.
              <p src="http://some.example/site/file/name.png"></p>
              Link to a <a href="page_url">page</a>.
            </p>
          end_content
        end
      end
    end
  end
end
