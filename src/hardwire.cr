# A Compile-time dependency injection system for Crystal.
#
# See `Root` for documentation on the container api.
module HardWire
  VERSION = "0.2.0"

  # Attach this annotation to a #initialize function to indicate which tags this method needs to resolve
  # for each dependency.
  # ```
  # @[HardWire::Tags(db_service: "secondary,primary")]
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

  # An Exception for indicating a duplicate registration at runtime.
  class AlreadyRegisteredException < Exception
    def initialize(@path : String, @lifecycle : Symbol, @tags = [] of Symbol)
      super("Failed to register new #{@lifecycle}, #{@path}#{@tags} Already registered")
    end
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
      @@registrations = [] of String
      # Store all registrations, which are mainly used to give nice errors for duplicate registrations
      # 
      # Users can also run their own checks at runtime for length, structure, etc.
      class_getter registrations

      def self.registered?(type : Class, tags : String) : Bool
        tagstring = "_" + tags.strip.split(",").map(&.strip).map(&.downcase).sort.join("_") 
        return @@registrations.any? { |e| e == type.name + tagstring}
      end

      def self.registered?(type : Class) : Bool
        return @@registrations.any? { |e| e == type.name }
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
      # * We keep a class var, `@@registrations`, which contains a stringified version of this dependency.
      #   This is used for making sure things have been registered/not registered twice. You can get this using the self.dependencies method
      # * Tags are converted into classes, so that they can be passed around at compile time. 
      #   This means you'll get missing const errors when you fail to register properly, but it should be clear why.
      macro register(path, lifecycle = :singleton, tags = nil, &block )
        # Normalize regtags to array of tags (string)
        \{% if tags != nil %}
          \{% regtags = tags.strip.split(",").map(&.strip).map(&.downcase).sort %}
        \{% else %}
          \{% regtags = [] of String %}
        \{% end %}

        \{% selftype = path.resolve %}
        \{% if ![:singleton, :transient].includes? lifecycle %}
          \{% raise "Unknown Lifecycle #{lifecycle}" %}
        \{% end %}

        if @@registrations.includes? "\{{selftype.id}}\{%for tag in regtags %}_\{{tag.id}}\{% end %}"
          raise ::HardWire::AlreadyRegisteredException.new( path: "\{{selftype.id}}",
            lifecycle: \{{lifecycle}},
            \{% if regtags.size > 0 %}
              tags:
                [\{% for tag in regtags %} :\{{tag.id}},\{% end %}]
              \{% end %}
            )
        end

        \{% safetype = selftype.stringify.gsub(/::/, "__") %}

        # The Tags module contains all registered tags as classes.
        #
        # These generated tags allow us to resolve constructors using static type information.
        module Tags
          module \{{safetype.id}}
            \{% for tag in regtags %}
              class \{{tag.upcase.id}}
              end
            \{% end %}
          end
        end

        \{% if lifecycle == :singleton %}
          # class var declaration for singleton
          @@\{{safetype.id}}\{%for tag in regtags %}_\{{tag.id}}\{% end %} : \{{selftype.id}}?
        \{% end %}

        # Resolve an instance of a class
        def self.resolve( type : \{{selftype.class}},  \{% for tag in regtags %} \{{tag.downcase.id}} : Tags::\{{safetype.id}}::\{{tag.upcase.id}}.class, \{% end %} ) : \{{selftype.id}}
          # Singletons: memoize to class var
          \{% if lifecycle == :singleton %}
            @@\{{safetype.id}}\{%for tag in regtags %}_\{{tag.id}}\{% end %} ||=
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
              \{% raise "Too many annotated constructors for #{path}" if annotated.size > 1 %}
              \{% constructor = annotated.first %}
            \{% else %}
              \{% constructor = inits.first %}
            \{% end %}

            \{% if constructor != nil %}
              \{% for arg in constructor.args %}
                \{{arg.name.id}}: self.resolve(
                  type: \{{arg.restriction}},

                  \{% argtags = [] of Type %}
                  \{% if tagannotation = constructor.annotation(::HardWire::Tags) %}
                    \{% for name, tagcsv in tagannotation.named_args %}
                      \{% if name == arg.name.id %}
                        \{% for tag in tagcsv.split(",").sort %}
                          \{% argtags.push tag.strip.id %}
                        \{% end %}
                      \{% end %}
                    \{% end %}

                    \{% for tag in argtags.sort %}
                      \{{tag}}: Tags::\{{arg.restriction.stringify.gsub(/::/, "__").id}}::\{{tag.upcase.id}},
                    \{% end %}
                  \{% end %}
                ),
              \{% end %}
            \{% end %}
            )
          \{% end %}
        end

        @@registrations.push "\{{selftype.id}}\{%for tag in regtags %}_\{{tag.id}}\{% end %}"
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
