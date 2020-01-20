require "./spec_helper"

class Service1; end
class Service2; end

class CheekyService
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

  @[HardWire::Tags(singleton1: "secondary,primary", singleton2: "secondary,primary", blockvalue: "teststring")]
  @[HardWire::Inject]
  def initialize(@singleton1 : CheekyService, @singleton2 : CheekyService, @blockvalue : String, @transient : CheekyService)
  end

  def initialize
    raise "This constructor should not be used! HardWire::Inject is not working"
    # cruft to satisfy compiler checks
    @singleton1 = CheekyService.new
    @singleton2 = CheekyService.new
    @blockvalue = "donotuse"
    @transient = CheekyService.new
  end
end

# This is all macros, so all the test fixtures have to be down _outside_?
# A bit strange, but should either fail to compile or fail to test, either will be workable.
module BasicContainer
  include HardWire::Container

  singleton String, "teststring" {
    "blockvalue"
  }
  singleton CheekyService, "secondary,primary"
  transient CheekyService
  singleton Application

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

  singleton CheekyService
end

describe HardWire do
  describe HardWire::Container do
    describe "#registered?" do
      it "should return true for a registered service with tags" do
        BasicContainer.registered?(CheekyService, "secondary,primary").should be_true
      end

      it "should return true for a registered service" do
        BasicContainer.registered?(CheekyService).should be_true
      end

      it "should return false for an unregistered service" do
        BasicContainer.registered?(Int32).should be_false
      end

      it "should return false for a service registered with different tags" do
        BasicContainer.registered?(CheekyService, "not,actual,tags").should be_false
      end
    end

    describe "#resolve" do
      it "should contain all the registered dependencies" do
        BasicContainer.registrations.size.should eq 6
        SecondContainer.registrations.size.should eq 1
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
        transient1 = BasicContainer.resolve CheekyService
        transient2 = BasicContainer.resolve CheekyService

        transient1.should_not eq transient2
      end
    end
  end
end
