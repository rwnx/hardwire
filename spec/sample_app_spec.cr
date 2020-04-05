require "./spec_helper"
require "./sample_app/*"

module SampleContainer
  include HardWire::Container

  singleton(SampleApp::DbService)

  singleton SampleApp::Application
end

describe "SampleApp" do
  it "should be able to resolve a dependency in another scope" do
    SampleContainer.resolve SampleApp::Application
  end
end
