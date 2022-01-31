require "../../src/hardwire"

class Singleton; end
class Scoped; end
class Transient; end

class DependsScoped
    def initialize(@dependency : Scoped)
    end
end

class Container
  include HardWire::Container

  scoped Scoped
  singleton DependsScoped
end

instance = Container.resolve DependsScoped

