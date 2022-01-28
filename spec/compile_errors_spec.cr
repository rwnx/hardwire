require "./spec_helper"

# These are pretty brittle, but the string message matching should be kept to the minimum required to indicate the error.
# This will give us the most flexibility for refactoring
describe "HardWire" do
  it "should fail to compile an unregistered dependency" do
    assert_compile_error "compile_errors/unregistered.cr", "Error: HardWire/MissingDependency"
  end

  it "should fail to compile a circular dependency" do
    assert_compile_error "compile_errors/circular.cr", "Error: HardWire/MissingDependency"
  end

  it "should fail to compile a duplicate dependency" do
    assert_compile_error "compile_errors/duplicate.cr", "Error: HardWire/DuplicateRegistration"
  end

  it "should fail to compile a duplicate dependency with tags" do
    assert_compile_error "compile_errors/duplicate_tags.cr", "Error: HardWire/DuplicateRegistration"
  end

  it "should fail to compile a duplicate dependency with a different lifecycle" do
    assert_compile_error "compile_errors/duplicate_singleton_transient.cr", "Error: HardWire/DuplicateRegistration"
    assert_compile_error "compile_errors/duplicate_singleton_scoped.cr", "Error: HardWire/DuplicateRegistration"
    assert_compile_error "compile_errors/duplicate_transient_scoped.cr", "Error: HardWire/DuplicateRegistration"
  end

  it "should fail to compile when a dependency has multiple, unannotated constructors" do
    assert_compile_error "compile_errors/constructor_unknown.cr", "Error: HardWire/UnknownConstructor"
  end

  it "should fail to compile when a dependency has multiple annotated constructors" do
    assert_compile_error "compile_errors/constructor_duplicate.cr", "Error: HardWire/TooManyConstructors"
  end

  it "should fail to compile when a dependency has commas in the tag" do
    assert_compile_error "compile_errors/invalid_tag_characters.cr", "Error: Hardwire/InvalidTagCharacters."
  end

  it "should fail to compile when a dependency is registered with the reserved `default` tag" do
    assert_compile_error "compile_errors/reserved_tag_default.cr", "Error: Hardwire/ReservedTag"
  end

  it "should fail to compile when a singleton depends on scoped" do
    assert_compile_error "compile_errors/singleton_depends_scoped.cr", "Error: Hardwire/DependsOnScoped"
  end

  it "should fail to compile when a singleton depends on scoped" do
    assert_compile_error "compile_errors/transient_depends_scoped.cr", "Error: Hardwire/DependsOnScoped"
  end
end
