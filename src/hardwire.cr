# A Compile-time non-intrusive dependency injection system for Crystal.
module HardWire
  # :nodoc:
  VERSION = {{ `shards version #{__DIR__}`.chomp.stringify }}

  # Attach this annotation to a #initialize function to indicate which tags this method needs to resolve
  # for each dependency.
  #
  # This annotation takes a key-value set of arguments matching argument names to tags.
  # ```
  # # resolve the db_service with tag "secondary"
  # @[HardWire::Tags(db_service: "secondary")]
  # def initialize(db_service : DbService)
  # ```
  annotation Tags
  end

  # Attach this annotation to a #initialize function in a multi-constructor class
  # to indicate that it is to be used for dependency injection.
  #
  # This annotation is not required when a class has one constructor only.
  # ```
  # def initialize
  #   # wont be used
  # end
  #
  # @[HardWire::Inject]
  # def initialize
  #   # will be used
  # end
  # ```
  annotation Inject
  end

  # A module mixin for creating a hardwire container.
  #
  # No functionality-based documentation will appear here, since the module is designed to be included
  # in other modules. See `HardWire::Root` for container-level functionality.
  # ```
  # module WhateverYouLikeContainer
  #   include Hardwire::Container
  # end
  # ```

  class TagClass; end

  module Container
    macro included
      # Store all registrations, which are mainly used to give nice errors for duplicate registrations
      #
      # Users can also run their own checks at runtime for length, structure, etc.
      REGISTRATIONS = [] of Tuple(String, String)

      # The Tags module contains all registered tags as classes.
      #
      # These generated tags allow us to resolve constructors using static type information.
      module Tags
      end

      # Interrogate the container for a registration
      def self.registered?(target : Class, tag = "default") : Bool
        return REGISTRATIONS.includes?({target.name, tag.strip.downcase})
      end

      # Resolve a dependency from a class and a string tag
      #
      # This macro does the legwork of mangling the dynamic-looking call into the statically-defined `resolve!` method
      #
      # NOTE: This method does not protect you from unregistered dependencies, since it relies on
      # directly resolving the `resolve!` method. If you need safety - use `registered?`
      macro resolve(target, tag = "default")
        {{@type}}.resolve!(\{{target}}, {{@type}}::Tags::\{{tag.upcase.id}} )
      end

      {% verbatim do %}

      # Register a transient dependency.
      macro transient(path, tags = nil, &block)
        {% if block %}
          register {{path}}, :transient, {{tags}} {{block}}
        {% else %}
          register {{path}}, :transient, {{tags}}
        {% end %}
      end

      # Register a transient dependency.
      macro transient(path, &block)
        transient({{path}}) {{block}}
      end

      # Register a contextis dependency.
      macro contextis(path, tags = nil, &block)
        {% if block %}
          register {{path}}, :contextis, {{tags}} {{block}}
        {% else %}
          register {{path}}, :contextis, {{tags}}
        {% end %}
      end

      # Register a contextis dependency.
      macro contextis(path, &block)
        contextis({{path}}) {{block}} 
      end

      # Register a singleton dependency.
      macro singleton(path, tags = nil, &block)
        {% if block %}
          register {{path}}, :singleton, {{tags}} {{block}}
        {% else %}
          register {{path}}, :singleton, {{tags}}
        {% end %}
      end

      # Register a singleton dependency.
      macro singleton(path, &block)
        singleton({{path}}) {{block}}
      end

      # Create a new registration from the passed type, lifecycle, and tags
      #
      # NOTE: that this is not designed to be user-facing - things like block capture are done in the `transient` `singleton` helpers
      # although this can't be made private because those are public.
      #
      # Registration is essentially making a constructor method (`self.resolve`) for the dependency,
      # that lives on the container.
      #
      # resolves are differentiated by signature, rather than any other dynamic feature, so incoming calls
      # route to the correct method without any dynamic-ness.
      #
      # There are also some checks that get carried out in the registration to catch errors up front
      # * We keep a class const, `REGISTRATIONS`, which contains a stringified version of this dependency.
      #   This is used for making sure things have been registered/not registered twice.
      # * Tags are converted into classes, so that they can be passed around at compile time.
      #   This means you'll get missing const errors when you fail to register properly, but it should be clear why.
      private macro register(path, lifecycle = :singleton, tag = nil, &block )
        {% raise "Hardwire/Reserved Tag: `default`. This is used internally - please choose a different name!" if tag == "default" %}
        {% tag = "default" if tag == nil %}
        {% raise "Hardwire/Invalid Tag Characters. #{tag}. Please use \\w+ patterns only" if tag =~ /[^\w]/ %}

        {% register_tag = tag.strip.downcase %}
        {% register_type = path.resolve %}
        {% register_type_safe = register_type.stringify.gsub(/[^\w]/, "_") %}
        {% register_tag_type = "Tags::#{register_tag.upcase.id}" %}

        {% if ![:singleton, :contextis, :transient].includes? lifecycle %}
          {% raise "Unknown Lifecycle #{lifecycle}" %}
        {% end %}

        {% if REGISTRATIONS.includes?({register_type.stringify, register_tag}) %}
          {% raise "HardWire/Duplicate Registration: existing (#{register_type.id}, #{register_tag})." %}
        {% end %}

        # Declare a tag as a namespaced class: Tags::TAGNAME
        class {{register_tag_type.id}} < HardWire::TagClass; end

        # Pre-declare singleton classvar if required (ambiguous block return types require this)
        {% if lifecycle == :singleton %}
          @@{{register_type_safe.id}}_{{register_tag.id}} : {{register_type.id}}?
        {% elsif lifecycle == :contextis %}
          class {{register_tag_type.id}}
            property _{{register_type_safe.id}}_{{register_tag.id}} : {{register_type.id}}?
            def self.instance
              Fiber.current.hard_wired[:{{"#{register_tag_type.id}"}}] ||= {{register_tag_type.id}}.new
              Fiber.current.hard_wired[:{{"#{register_tag_type.id}"}}].as({{register_tag_type.id}})
            end
          end
        {% end %}

        # Define a resolve! method that instantiates the dependency that's being registered,
        # either through the block provided or introspection on the constructor.
        def self.resolve!( type : {{register_type.class}}, {{register_tag.id}} : {{register_tag_type.id}}.class ) : {{register_type.id}}
          # Singletons: memoize to class var
          {% if lifecycle == :singleton %}
            @@{{register_type_safe.id}}_{{register_tag.id}} ||=
          {% elsif lifecycle == :contextis %}
            {{register_tag_type.id}}.instance._{{register_type_safe.id}}_{{register_tag.id}} ||=
          {% end %}

          {% if block %}
            ({{block.body}})
          {% else %}
            {{register_type.id}}.new(
              {% found_ctors = register_type.methods.select(&.name.==("initialize")) %}
              # If multiple constructors are found, we want the annotated one
              {% if found_ctors.size > 1 %}
                {% annotated_ctors = found_ctors.select(&.annotation(::HardWire::Inject)) %}
                {% raise "HardWire/Too Many Constructors: target: #{path}. Only one constructor can be annotated with @[HardWire::Inject]." if annotated_ctors.size > 1 %}
                {% raise "HardWire/Unknown Constructor: target: #{path}. Annotate your injectable constructor with @[HardWire::Inject]" if annotated_ctors.size < 1 %}
                {% constructor = annotated_ctors.first %}
              {% else %}
                {% constructor = found_ctors.first %}
              {% end %}

              {% if constructor != nil %}
                {% for arg in constructor.args %}
                  {% dependency_name = arg.name.id %}
                  {% dependency_type = arg.restriction.resolve %}
                  {% dependency_tag = "default" %}

                  {% if tagannotation = constructor.annotation(::HardWire::Tags) %}
                    {% for name, annotation_tag in tagannotation.named_args %}
                      {% if name == dependency_name %}
                        {% dependency_tag = annotation_tag.strip.downcase %}
                      {% end %}
                    {% end %}
                  {% end %}

                  {% if !REGISTRATIONS.includes?({dependency_type.name.stringify, dependency_tag}) %}
                    {% raise "HardWire/Missing Dependency: unabled to register (#{register_type.id}, #{register_tag}), missing #{arg.name}: (#{dependency_type}, #{dependency_tag})" %}
                  {% end %}

                  {{dependency_name}}: self.resolve!(
                    type: {{dependency_type}},
                    {{dependency_tag}}: Tags::{{dependency_tag.upcase.id}}
                  ),
                {% end %}
              {% end %}
            )
          {% end %}
        end

        {% REGISTRATIONS << {register_type.stringify, register_tag} %}
      end

      {% end %}
    end
  end

  # A pre-made Container, designed to provide a concrete in-namespace module to generate documentation from.
  #
  # NOTE: All of the methods in this library are designed to operate _inside_ the container class,
  # so you cannot use this container for actual dependency injection
  module Root
    include Container
  end
end

class Fiber
  property hard_wired = Hash(Symbol, HardWire::TagClass).new
end
