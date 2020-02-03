require "../../src/hardwire"

class SpecialService
end

class Container
  include HardWire::Container

  singleton SpecialService, "onetwo"
  singleton SpecialService, "onetwothree" # not a duplicate
  transient SpecialService, "onetwo"
end

