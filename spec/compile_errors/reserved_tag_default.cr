require "../../src/hardwire"

class SpecialService
end

class Container
  include HardWire::Container

  singleton SpecialService, "default"
end

