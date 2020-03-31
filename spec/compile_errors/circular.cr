require "../../src/hardwire"

class Dep1
  def initialize(@dep2 : Dep2)
  end
end

class Dep2
  def initialize(@dep1 : Dep1)
  end
end

module CircContainer
  include HardWire::Container
  singleton Dep1
  singleton Dep2
end
