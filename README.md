# HardWire ⚡
[![Crystal CI](https://github.com/jerometwell/hardwire/workflows/Crystal%20CI/badge.svg?branch=master)](https://github.com/jerometwell/hardwire/actions?query=workflow%3A%22Crystal+CI%22)

A Compile-time Dependency Injection system for Crystal.

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  hardwire:
    github: jerometwell/hardwire
```

2. Run `shards install`

## Usage

```crystal
require "hardwire"
```

Hardwire is designed to operate inside a container object.
Since the resolution is compile-time (Using Macros), normally this will be a module.

### Creating a container 📦
```crystal
# To create a new container, include `HardWire::Container`
# This will add the macros you need to register and resolve wiring
module Container
  include HardWire::Container

  # use transient/singleton to wire different lifecycles
  # singleton dependencies will be memoized
  # dependencies for the constructor will be resolved from the constructor automatically
  transient Dependency
  singleton NeedsDependency

  # you can also register dependencies with a block instead of inspecting the constructor
  # Your block MUST return an instance of the class you are registering
  singleton NeedsDependency {
    NeedsDependency.new( self.resolve Dependency )
  }
end
```

Hardwire tries to operate with minimal modifications to other classes (unless required).
"_simple_" classes, e.g.
  * Have a single constructor
  * Have unique dependencies/do not require tags

If your classes match this signature, you can wire up in the container without adding anything to the classes.

For everything else, there's:

### Multiple Constructors 🚧
Hardwire needs to know which constuctor function to use.

Annotate your "Injectable" constructor with the Hardwire::Inject annotation.
```crystal
class MultipleInits
  @[HardWire::Inject]
  def initialize(input: String)
    # register will inspect this method's arguments
    # [...]
  end

  def initialize
    # will not be used for injection
    # [...]
  end
end
```

### Tags 🏷
To differentiate between registrations of _the same type_, use the HardWire::Tags annotation.
Tags allow you to attach additional metadata to the signature. Tags themselves are string-based, simple identifiers (/\w+/) that allow you to resolve
a different registration of the same class.


```crystal
# [...]

# registering a transient dependency with tag "secret"
transient String, "secret" {
  "a secret string"
}

# registering a singleton
# When no tags are set, it is considered the "default" registration
singleton DbService

# registering a different singleton with a tag
singleton DbService, "primary"

# Resolving Dependencies
class Resolving
  @[Hardwire::Tags(input: "secret", primary_db: "primary")]
  def initialize(input : String, primary_db : DbService, default_db : DbService)
  end
end
```

### Resolving Manually 🔨
You can resolve dependencies manually using the `.resolve` macro. This allows you to resolve dependencies manually with the tag string.

```crystal
module Container
  include HardWire::Container

  transient SecretService, "primary"
  singleton DatabaseThing
end

service = Container.resolve SecretService, "primary"
db = Container.resolve DatabaseThing
```

### Runtime Interrogation 👀
Hardwire can tell you information about the registrations at runtime, but the dependencies are _HardWired_ (See what I did there?), so they can't be changed.

```crystal
module Container
  include HardWire::Container

  singleton DbService
end

Container.registered?(DbService) # true
Container.registered?(DbService, "tagged") # false
Container.registered?(String) # false
```

## Contributing

1. Fork it (<https://github.com/jerometwell/hardwire/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Rowan Twell](https://github.com/jerometwell) - creator and maintainer
