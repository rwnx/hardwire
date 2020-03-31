require "../../src/hardwire"

class ParentService
end

class SpecialService
  # too many annotated constructors
  @[HardWire::Inject]
  def initialize(@parentService : ParentService)
  end

  # too many annotated constructors
  @[HardWire::Inject]
  def initialize(string : String)
    @parentService = ParentService.new
  end
end

class Container
  include HardWire::Container

  singleton ParentService
  transient SpecialService
end
