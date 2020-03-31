require "./spec_helper"

# These are pretty brittle, but the string message matching should be kept to the minimum required to indicate the error.
# This will give us the most flexibility for refactoring
describe "HardWire" do
  it "should fail to compile an unregistered dependency" do
    assert_compile_error "compile_errors/unregistered.cr", "Error: HardWire/Missing Dependency: unabled to register (ParentService, \"default\"), missing required_dependency: (RequiredDependency, \"default\")"
  end

  it "should fail to compile a circular dependency" do
    assert_compile_error "compile_errors/circular.cr", "Error: HardWire/Missing Dependency: unabled to register (Dep1, \"default\"), missing dep2: (Dep2, \"default\")"
  end

  it "should fail to compile a duplicate dependency" do
    assert_compile_error "compile_errors/duplicate.cr", "Error: HardWire/Duplicate Registration: existing (SpecialService, \"default\")."
  end

  it "should fail to compile a duplicate dependency with tags" do
    assert_compile_error "compile_errors/duplicate_tags.cr", "Error: HardWire/Duplicate Registration: existing (SpecialService, \"onetwo\")"
  end

  it "should fail to compile a duplicate dependency with a different lifecycle" do
    assert_compile_error "compile_errors/duplicate_different_lifecycles.cr", "Error: HardWire/Duplicate Registration: existing (SpecialService, \"default\")"
  end

  it "should fail to compile when a dependency has multiple, unannotated constructors" do
    assert_compile_error "compile_errors/constructor_unknown.cr", "Error: HardWire/Unknown Constructor: target: SpecialService."
  end

  it "should fail to compile when a dependency has multiple annotated constructors" do
    assert_compile_error "compile_errors/constructor_duplicate.cr", "Error: HardWire/Too Many Constructors: target: SpecialService."
  end

  it "should fail to compile when a dependency has commas in the tag" do
    assert_compile_error "compile_errors/invalid_tag_characters.cr", "Error: Hardwire/Invalid Tag Characters."
  end

  it "should fail to compile when a dependency is registered with the reserved `default` tag" do
    assert_compile_error "compile_errors/reserved_tag_default.cr", "Error: Hardwire/Reserved Tag: `default`."
  end
end
