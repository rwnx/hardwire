require "./spec_helper"

class Singleton; end

class Scoped; end

class Transient; end

class ScopedNeedsSingleton
  def initialize(@singleton : Singleton)
  end

  getter singleton
end

class ScopedNeedsScoped
  def initialize(@scoped : Scoped)
  end

  getter scoped
end

class Container
  include HardWire::Container

  singleton Singleton
  scoped Scoped
  transient Transient

  scoped ScopedNeedsSingleton
  scoped ScopedNeedsScoped
end

describe "Scopes" do
  it "should resolve different instances in different scopes" do
    scope_1 = Container.scope
    scope_2 = Container.scope
    instance_1 = scope_1.resolve ScopedNeedsSingleton
    instance_2 = scope_2.resolve ScopedNeedsSingleton

    instance_1.should_not be instance_2
  end

  it "should propagate scope resolution in nested depedencies" do
    scope = Container.scope

    nested_dependency = scope.resolve Scoped
    instance = scope.resolve ScopedNeedsScoped

    instance.scoped.should be nested_dependency
  end

  it "should resolve the same nested singleton from a scope" do
    singleton_instance = Container.resolve Singleton
    scope = Container.scope
    scoped_instance = scope.resolve ScopedNeedsSingleton

    scoped_instance.singleton.should be singleton_instance
  end

  it "resolving a singleton in a scope should result in the same instance" do
    scope = Container.scope

    resolved_singleton = Container.resolve Singleton
    scope_resolved_singleton = scope.resolve Singleton

    resolved_singleton.should be scope_resolved_singleton
  end

  it "resolving a transient in a scope should result in different instances" do
    scope = Container.scope

    container_transient = Container.resolve Transient
    scope_transient = scope.resolve Transient

    container_transient.should_not be scope_transient
  end

  it "creating a lifecycle scope with the same name as an already initialized scope should fail" do
    expect_raises(Exception) do
      scope1 = Container.scope "test_scope"
      scope1.resolve Scoped

      scope2 = Container.scope "test_scope"
    end
  end

  it "attempting to init a scope with a reserved name should fail" do
    expect_raises(Exception) do
      scope1 = Container.scope "singleton"
    end
  end

  it "after destroying a scope, resolving from the same scope should generate a new instance" do
    scope = Container.scope

    resolved_first = scope.resolve Scoped
    scope.destroy

    resolved_second = scope.resolve Scoped

    resolved_first.should_not be resolved_second
  end

  it "after destroying a scope, singletons should be the same instance" do
    scope = Container.scope

    resolved_first = scope.resolve Singleton
    scope.destroy

    resolved_second = scope.resolve Singleton

    resolved_first.should be resolved_second
  end

  it "destroying a scope that was never used should have no effect" do
    scope = Container.scope
    scope.destroy
  end
end
