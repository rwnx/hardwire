require "../../src/hardwire"

class RequiredDependency
end

class ParentService
  def initialize(@requiredDependency : RequiredDependency)
  end
end

module CircContainer
  include HardWire::Container

  singleton ParentService
end
