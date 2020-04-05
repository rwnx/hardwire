require "./spec_helper"

class Service1; end

class Service2; end

class Deep::Nested::Item; end

class ChildService
  @@instances = 0

  def initialize
    @@instances += 1
  end

  def do_stuff
    pp "there are #{@@instances} instances of #{self.class.name}"
  end
end

class Application
  property singleton1
  property singleton2
  property transient
  property blockvalue

  @[HardWire::Tags(singleton1: "primary", singleton2: "primary", blockvalue: "teststring")]
  @[HardWire::Inject]
  def initialize(@singleton1 : ChildService, @singleton2 : ChildService, @blockvalue : String, @transient : ChildService)
  end

  def initialize
    raise "This constructor should not be used! HardWire::Inject is not working"
    # cruft to satisfy compiler checks
    # ameba:disable Lint/UnreachableCode
    @singleton1 = ChildService.new
    @singleton2 = ChildService.new
    @blockvalue = "donotuse"
    @transient = ChildService.new
  end
end

# This is all macros, so all the test fixtures have to be down _outside_?
# A bit strange, but should either fail to compile or fail to test, either will be workable.
module BasicContainer
  include HardWire::Container

  singleton String, "teststring" {
    "blockvalue"
  }
  singleton ChildService, "primary"
  transient ChildService, "secondary"
  transient ChildService
  singleton Application

  singleton Deep::Nested::Item

  # no tags, just block
  transient(Service1) {
    Service1.new
  }

  # no tags, just block
  singleton(Service2) {
    Service2.new
  }
end

module SecondContainer
  include HardWire::Container

  singleton ChildService
end

class DifferentScopedThing
  def initialize(@nested : Deep::Nested::Item)
  end
end

module Deep::Nested
  module Container
    include HardWire::Container

    # Registering in a different scope than will be used to resolve it
    singleton Item

    # Depends on Deep::Nested::Item, not Item
    singleton DifferentScopedThing
  end
end

pp HardWire::VERSION

describe HardWire do
  describe HardWire::Container do
    describe "#registered?" do
      it "should return true for a registered service with tags" do
        BasicContainer.registered?(ChildService, "secondary").should be_true
      end

      it "should return true for a registered service" do
        BasicContainer.registered?(ChildService).should be_true
      end

      it "should return false for an unregistered service" do
        BasicContainer.registered?(Int32).should be_false
      end

      it "should return false for a service registered with different tags" do
        BasicContainer.registered?(ChildService, "notactualtag").should be_false
      end
    end

    describe "#resolve" do
      it "should resolve a deeply nested dependency" do
        BasicContainer.resolve Deep::Nested::Item
      end

      it "should resolve a tagged dependency" do
        BasicContainer.resolve ChildService, "primary"
      end

      it "should resolve block registrations correctly" do
        app = BasicContainer.resolve Application
        app.blockvalue.should eq "blockvalue"
      end

      it "should memoize singletons" do
        app = BasicContainer.resolve Application

        app.singleton1.should eq app.singleton2
      end

      it "should NOT memoize transients" do
        transient1 = BasicContainer.resolve ChildService
        transient2 = BasicContainer.resolve ChildService

        transient1.should_not eq transient2
      end

      it "should resolve a dependency in an alternate scope" do
        Deep::Nested::Container.resolve DifferentScopedThing
      end
    end
  end
end
