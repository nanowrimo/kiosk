require 'spec_helper'

describe Kiosk do
  subject { Kiosk }

  let(:config) { {'origins' => {'default' => {'site' => 'http://cms.example'}}} }

  before(:each) do
    Kiosk.instance_variable_set(:@config, nil)
    Kiosk.instance_variable_set(:@origins, nil)
  end

  describe ".config" do
    before(:each) do
      File.should_receive(:open).with("#{Rails.root}/config/kiosk.yml").and_return('config_path')
      YAML.should_receive(:load).with('config_path').and_return(config)
    end

    it("returns the parsed config") { subject.config.should be(config) }
  end

  describe ".origin" do
    subject { Kiosk.origin }

    before(:each) { Kiosk.stub(:config) { config } }

    context "with an explicit environment config" do
      let(:config) { {'origins' => {Rails.env => {'site' => 'env_site'}}} }

      it { should be_a(Kiosk::Origin) }
      it("returns the environment origin") { subject.site.should == 'env_site/' }
    end

    context "with only a default environment config" do
      let(:config) { {'origins' => {'default' => {'site' => 'default_site'}}} }

      it { should be_a(Kiosk::Origin) }
      it("returns the default origin") { subject.site.should == 'default_site/' }
    end
  end
end
