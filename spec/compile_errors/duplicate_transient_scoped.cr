require "../../src/hardwire"

class SpecialService
end

class Container
  include HardWire::Container

  transient SpecialService
  scoped SpecialService
end
