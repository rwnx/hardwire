require "../../src/hardwire"

class RequiredDependency
end

class ParentService
  def initialize(@required_dependency : RequiredDependency)
  end
end

module CircContainer
  include HardWire::Container

  singleton ParentService
end
