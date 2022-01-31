require "../../src/hardwire"

class SpecialService
end

class Container
  include HardWire::Container

  singleton SpecialService
  scoped SpecialService
end
