require "../../src/hardwire"

class ParentService
end

class SpecialService
  def initialize(@parent_service : ParentService)
  end

  # null constructor - how confusing
  def initialize
    @parent_service = ParentService.new
  end
end

class Container
  include HardWire::Container

  singleton ParentService
  transient SpecialService
end
