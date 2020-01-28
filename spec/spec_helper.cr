require "spec"
require "../src/hardwire"

# Pinched from Blacksmoke16
# https://forum.crystal-lang.org/t/testing-compile-time-errors/272/3
def assert_compile_error(path : String, message : String) : Nil
  buffer = IO::Memory.new
  result = Process.run("crystal", ["run", "--no-color", "--no-codegen", "spec/" + path], error: buffer)
  result.success?.should be_false
  buffer.to_s.should contain message
  buffer.close
end
