require "../../src/hardwire"

class ParentService
end

class SpecialService
  # too many annotated constructors
  @[HardWire::Inject]
  def initialize(@parent_service : ParentService)
  end

  # too many annotated constructors
  @[HardWire::Inject]
  def initialize(string : String)
    @parent_service = ParentService.new
  end
end

class Container
  include HardWire::Container

  singleton ParentService
  transient SpecialService
end
