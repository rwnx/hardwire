require "../../src/hardwire"

class SpecialService
end

class Container
  include HardWire::Container

  singleton SpecialService, "one,two"
  singleton SpecialService, "one,two,three" # not a duplicate
  transient SpecialService, "one,two"
end

