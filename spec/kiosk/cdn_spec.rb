require 'spec_helper'

require 'nokogiri'

module Kiosk
  describe Cdn do
    let(:cdn) { Cdn.new(config) }
    let(:config) { { 'host' => cdn_host } }
    let(:cdn_host) { 'some.cdn.example' }
    let(:uri_value) { 'http://some.example/path' }

    let(:node) { Nokogiri::XML::Node.new('a', Nokogiri::XML::Document.new).extend(ClaimedNode) }

    before do
      node['src'] = uri_value
      node.extend(ClaimedNode)
    end

    describe "#rewrite_node" do
      let(:invocation) { proc { cdn.rewrite_node(node) } }

      context "the invocation" do
        subject { invocation }

        context "when a CDN is not configured" do
          let(:cdn_host) { nil }

          it { should_not raise_error }
          its(:call) { should be_nil }
        end

        context "when the URI-attribute value is invalid" do
          let(:uri_value) { ':bad.example' }

          it { should_not raise_error }
          its(:call) { should be_nil }
        end

        context "when the URI-attribute value is valid" do
          let(:uri_value) { 'http://good.example/path' }

          it { should_not raise_error }
        end
      end

      context "the resulting URI-attribute value" do
        subject { URI.parse(node.uri_attribute.content) }

        before { invocation.call }

        context "when the CDN host is provided" do
          context "as just the hostname" do
            let(:cdn_host) { 'hostname.example' }
            its(:to_s) { should == 'http://hostname.example/path' }
          end

          context "as a URI" do
            context "with a scheme" do
              let(:cdn_host) { 'https://proto.example' }
              its(:scheme) { should == 'https' }
              its(:host) { should == 'proto.example' }
              its(:path) { should == '/path' }
              its(:to_s) { should == 'https://proto.example/path' }
            end

            context "without a scheme" do
              let(:cdn_host) { '//proto-relative.example' }
              its(:scheme) { should be_nil }
              its(:host) { should == 'proto-relative.example' }
              its(:path) { should == '/path' }
              its(:to_s) { should == '//proto-relative.example/path' }
            end

            context "with a path" do
              let(:cdn_host) { 'http://path.example/prefix/' }
              its(:path) { should == '/prefix/path' }
              its(:to_s) { should == 'http://path.example/prefix/path' }
            end
          end
        end
      end
    end
  end
end
