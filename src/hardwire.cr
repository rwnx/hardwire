# A Compile-time dependency injection system for Crystal.
#
# See `Root` for documentation on the container api.
module HardWire
  # This constant is provided for convenience only! You must update shard.yml when updating the version.
  VERSION = "0.3.1"

  # Attach this annotation to a #initialize function to indicate which tags this method needs to resolve
  # for each dependency.
  # ```
  # @[HardWire::Tags(db_service: "secondary")]
  # def initialize(db_service : DbService)
  # ```
  # Use keys that match the arguments you're trying to inject, and csv-strings for tags
  annotation Tags
  end

  # Attach this annotation to a #initialize function in a multi-constructor class
  # to indicate that it is to be used for dependency injection.
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
  # Contains a set of class-level methods and macros for registering and interrogating the container.
  # As all the functionality is contained in macros, see `Root` to an implementation example.
  # ```
  # module WhateverYouLikeContainer
  #   include Hardwire::Container
  # end
  # ```
  module Container
    macro included
      # Store all registrations, which are mainly used to give nice errors for duplicate registrations
      #
      # Users can also run their own checks at runtime for length, structure, etc.
      REGISTRATIONS = [] of String

      def self.registered?(target : Class) : Bool
        self.registered?(target, "default")
      end

      def self.registered?(target : Class, tagstring : String) : Bool
        tagstring = "_" + tagstring.strip.downcase
        return REGISTRATIONS.includes? target.name + tagstring
      end

      macro resolve(target, resolve_tag = "default")
        {{@type}}.resolve!(\{{target}}, {{@type}}::Tags::\{{target.resolve.stringify.gsub(/[^\w]/, "_").id}}::\{{resolve_tag.upcase.id}} )
      end

      # Create a new registration from the passed type, lifecycle, and tags
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
      macro register(path, lifecycle = :singleton, tagstring = nil, &block )

        \{% raise "Hardwire/Reserved Tag: `default`. This is used internally - please choose a different name!" if tagstring == "default" %}
        \{% tagstring = "default" if tagstring == nil %}
        \{% raise "Hardwire/Invalid Tag Characters. #{tagstring}. Please use \\w+ patterns only" if tagstring =~ /[^\w]/  %}

        \{% register_tag = tagstring.strip.downcase %}

        \{% selftype = path.resolve %}
        \{% if ![:singleton, :transient].includes? lifecycle %}
          \{% raise "Unknown Lifecycle #{lifecycle}" %}
        \{% end %}

        \{% if REGISTRATIONS.includes? "#{selftype.id}_#{register_tag.id}" %}
          \{% raise "HardWire/Duplicate Registration: existing (#{selftype.id}, #{register_tag})." %}
        \{% end %}


        \{% safetype = selftype.stringify.gsub(/[^\w]/, "_") %}

        # The Tags module contains all registered tags as classes.
        #
        # These generated tags allow us to resolve constructors using static type information.
        module Tags
          module \{{safetype.id}}
            class \{{register_tag.upcase.id}}
            end
          end
        end

        \{% if lifecycle == :singleton %}
          # class var declaration for singleton
          @@\{{safetype.id}}_\{{register_tag.id}} : \{{selftype.id}}?
        \{% end %}

        # Resolve an instance of a class
        def self.resolve!( type : \{{selftype.class}}, \{{register_tag.id}} : Tags::\{{safetype.id}}::\{{register_tag.upcase.id}}.class ) : \{{selftype.id}}
          # Singletons: memoize to class var
          \{% if lifecycle == :singleton %}
            @@\{{safetype.id}}_\{{register_tag.id}} ||=
          \{% end %}

          \{% if block %}
            # block passed - use custom init with resolve, etc
            (\{{block.body}})
          \{% else %}
            # No block - introspection time.
            \{{selftype.id}}.new(
            \{% inits = selftype.methods.select { |m| m.name == "initialize" } %}
            # If multiple constructors are found, we want the annotated one
            \{% if inits.size > 1 %}
              \{% annotated = inits.select { |m| m.annotation(::HardWire::Inject) } %}
              \{% raise "HardWire/Too Many Constructors: target: #{path}. Only one constructor can be annotated with @[HardWire::Inject]." if annotated.size > 1 %}
              \{% raise "HardWire/Unknown Constructor: target: #{path}. Annotate your injectable constructor with @[HardWire::Inject]" if annotated.size < 1 %}
              \{% constructor = annotated.first %}
            \{% else %}
              \{% constructor = inits.first %}
            \{% end %}

            \{% if constructor != nil %}
              \{% for arg in constructor.args %}

                \{{arg.name.id}}: self.resolve!(
                  type: \{{arg.restriction}},

                  \{% resolve_tag = "default" %}

                  \{% if tagannotation = constructor.annotation(::HardWire::Tags) %}
                    \{% for name, annotation_tag in tagannotation.named_args %}
                      \{% if name == arg.name.id %}
                        \{% resolve_tag = annotation_tag.strip.downcase.id %}
                      \{% end %}
                    \{% end %}

                    \{{resolve_tag}}: Tags::\{{arg.restriction.stringify.gsub(/[^\w]/, "_").id}}::\{{resolve_tag.upcase.id}}
                  \{% end %}

                  \{% if !REGISTRATIONS.includes? "#{arg.restriction.id}_#{resolve_tag.id}" %}
                    \{% raise "HardWire/Missing Dependency: unabled to register (#{selftype.id}, #{register_tag}), missing #{arg.name}: (#{arg.restriction}, #{resolve_tag})" %}
                  \{% end %}
                ),
              \{% end %}
            \{% end %}
            )
          \{% end %}
        end

        \{% REGISTRATIONS << "#{selftype.id}_#{register_tag.id}" %}
      end

      # Register a transient dependency.
      macro transient(path, tags = nil, &block)
        \{% if block %}
          register \{{path}}, :transient, \{{tags}} \{{block}}
        \{% else %}
          register \{{path}}, :transient, \{{tags}}
        \{% end %}
      end

      # Register a singleton dependency.
      macro singleton(path, tags = nil, &block)
        \{% if block %}
          register \{{path}}, :singleton, \{{tags}} \{{block}}
        \{% else %}
          register \{{path}}, :singleton, \{{tags}}
        \{% end %}
      end

      # Register a transient dependency.
      macro transient(path, &block)
          transient(\{{path}}) \{{block}}
      end

      # Register a singleton dependency.
      macro singleton(path, &block)
          singleton(\{{path}}) \{{block}}
      end
    end
  end

  # A "Global" namespaced Container.
  #
  # Consumers of the library can use this without creating their own.
  #
  # We can also use it as an example of our macros, for documentation purposes.
  module Root
    include Container
  end
end
