require "../../src/hardwire"

class ParentService
end

class SpecialService
  def initialize(@parentService : ParentService)
  end

  # null constructor - how confusing
  def initialize
    @parentService = ParentService.new
  end
end

class Container
  include HardWire::Container

  singleton ParentService
  transient SpecialService
end

