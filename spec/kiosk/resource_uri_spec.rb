require 'spec_helper'

module Kiosk
  describe ResourceURI do
    before(:each) do
      @uri = ResourceURI.parse('http://some.example/site/some/blarby/post/123')

      @origin = Origin.new({'site' => 'http://some.example/site/'})
      Kiosk.should_receive(:origin).and_return(@origin)
    end

    describe "#match" do
      context "given a matching pattern with attributes" do
        subject { @uri.match('some/!word/:type/:id') }

        it("matches") { should_not be_nil }
        it("returns the parsed attributes") { should == {:type => 'post', :id => '123'} }
        it("excludes the bang token") { should_not include(:word) }
      end

      context "given a non-matching pattern" do
        subject { @uri.match('some/\d+/:type/:id') }

        it("returns nil") { should be_nil }
      end

      context "given this pattern" do
        before(:each) do
          @uri = ResourceURI.parse('http://some.example/site/2011/05/11/what-is-nanowrimo/')
        end

        subject { @uri.match('\d{4}/\d{2}/\d{2}/:slug') }

        it("returns the parsed attributes") { should == {:slug => 'what-is-nanowrimo'} }
      end

      context "given a pattern that would match the site path" do
        subject { @uri.match('site/some/!word/:type/:id') }

        it("does not match") { should be_nil }
      end
    end
  end
end
