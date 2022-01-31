require "uuid"
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
  module Container
    macro included
      # Store all registrations, which are mainly used to give nice errors for duplicate registrations
      #
      # Users can also run their own checks at runtime for length, structure, etc.
      REGISTRATIONS = [] of NamedTuple(type: String, tag: String, lifecycle: Symbol)

      # Interrogate the container for a registration
      def self.registered?(target : Class, tag = "default") : Bool
        return REGISTRATIONS.any? {|x| x[:type] == target.name && x[:tag] == tag }
      end

      # Resolve a dependency from a class and a string tag
      #
      # This macro does the legwork of mangling the dynamic-looking call into the statically-defined `resolve!` method
      #
      # NOTE: This method does not protect you from unregistered dependencies, since it relies on
      # directly resolving the `resolve!` method. If you need safety - use `registered?`
      macro resolve(target, tag = "default")
        {{@type}}.resolve!(\{{target}}, \{{tag}})
      end

      # create a new scope with the specified name
      macro scope(name)
        {{@type}}::Scope.new(\{{name}})
      end
      
      # Create a new scope with a randomly chosen unique ID
      macro scope()
        {{@type}}::Scope.new(UUID.random.to_s)
      end

      # A Scope is an object that represents the a scope's lifecycle
      # 
      # It is a a helper class for accessing scoped resolution
      # and providing a lifecycle hook to destroy/garbage collect the scoped instances
      #
      # Scopes work in exactly the same way that singleton lifecycles do, except that the user has control
      # over when the instances stored inside are released for garbage collection.
      #
      # NOTE: you should not construct these directly, instead prefering to use the `.scope` macro on the container module
      class Scope
        def initialize(@name : String)
          if @name == "singleton"
            raise "Hardwire/ReservedScope: the scope 'singleton' is used internally, please choose a different name"
          end

          if {{@type}}.has_scope? @name
            raise "Hardwire/ExistingScope: the scope #{@name} already exists"
          end
        end

        # Resolve a dependency from the represented scope
        def resolve(target : Class, tag = "default")
          {{@type}}.resolve!(target, tag, scope: @name)
        end

        # Destroy the represented scope and release the instances for garbage collection
        #
        # NOTE: this will be called when the scope itself is garbage-collected
        def destroy
          {{@type}}.destroy_scope @name
        end

        def finalize
          # Invoked when Foo is garbage-collected
          self.destroy
        end

        getter name
      end

      {% verbatim do %}

      # Register a transient dependency.
      macro transient(path, tag = nil, &block)
        {% if block %}
          register {{path}}, :transient, {{tag}} {{block}}
        {% else %}
          register {{path}}, :transient, {{tag}}
        {% end %}
      end

      # Register a transient dependency.
      macro transient(path, &block)
        transient({{path}}) {{block}}
      end

      # Register a singleton dependency.
      macro singleton(path, tag = nil, &block)
        {% if block %}
          register {{path}}, :singleton, {{tag}} {{block}}
        {% else %}
          register {{path}}, :singleton, {{tag}}
        {% end %}
      end

      # Register a singleton dependency.
      macro singleton(path, &block)
          singleton({{path}}) {{block}}
      end

      # Register a scoped dependency.
      macro scoped(path, tag = nil, &block)
        {% if block %}
          register {{path}}, :scoped, {{tag}} {{block}}
        {% else %}
          register {{path}}, :scoped, {{tag}}
        {% end %}
      end

      # Register a singleton dependency.
      macro scoped(path, &block)
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
      private macro register(path, lifecycle, tag = nil, &block)
        {% raise "Hardwire/ReservedTag: `default`. This is used internally - please choose a different name!" if tag == "default" %}
        {% tag = "default" if tag == nil %}
        {% raise "Hardwire/InvalidTagCharacters. #{tag}. Please use \\w+ patterns only" if tag =~ /[^\w]/ %}

        {% register_tag = tag.strip.downcase %}
        {% register_type = path.resolve %}
        {% register_type_safe = register_type.stringify.gsub(/[^\w]/, "_") %}
        

        {% if flag? :debug %}
          {% puts "% Registering: #{lifecycle} #{register_type}[#{register_tag.id}]"%}
        {% end %}

        {% if ![:singleton, :scoped, :transient].includes? lifecycle %}
          {% raise "Unknown Lifecycle #{lifecycle}" %}
        {% end %}

        {% if REGISTRATIONS.any? {|x| x[:type] == register_type.stringify && x[:tag] == register_tag } %}
          {% raise "HardWire/DuplicateRegistration: existing #{register_type}[#{register_tag.id}]" %}
        {% end %}
        
        # Define a resolve! method that instantiates the dependency that's being registered,
        # either through the block provided or introspection on the constructor.
        {% if REGISTRATIONS.any? {|x| x[:type] == register_type.stringify } %}
          {% if flag? :debug %}
            {% puts "% skipping resolve definition for (#{lifecycle}): #{register_type}, already present" %}
          {% end %}
        {% else %}

          # Pre-declare lifecycle classvar if required (ambiguous block return types require this)
          # Required declarative for cross-scopes as well
          @@instances_{{register_type_safe.id}} = Hash(String, Hash(String, {{register_type.id}})).new

          def self.resolve!( type : {{register_type.class}}, tag : String, scope : String = "singleton") : {{register_type.id}}
            # Do not propagate scope resolution if dependency was registered as a singleton
            singleton_reg = REGISTRATIONS.any? {|x| x[:type] == type.name && x[:tag] == tag && x[:lifecycle] == :singleton  }
            if singleton_reg
              scope = "singleton"
            end
            scoped_reg = REGISTRATIONS.any? {|x| x[:type] == type.name && x[:tag] == tag && x[:lifecycle] == :scoped }
            lifecycle_required = singleton_reg || scoped_reg

            {% if flag? :debug %}
              puts "% Resolving: #{type}: [#{tag}]"
            {% end %}
            if lifecycle_required
              if @@instances_{{register_type_safe.id}}.dig? scope, tag
                return @@instances_{{register_type_safe.id}}[scope][tag]
              end
            end
          
            tempvar : {{register_type.id}} = 
            {% if block %}
              ({{block.body}})
            {% else %}
              {{register_type.id}}.new(
                {% found_ctors = register_type.methods.select(&.name.==("initialize")) %}
                # If multiple constructors are found, we want the annotated one
                {% if found_ctors.size > 1 %}
                  {% annotated_ctors = found_ctors.select(&.annotation(::HardWire::Inject)) %}
                  {% raise "HardWire/TooManyConstructors: target: #{path}. Only one constructor can be annotated with @[HardWire::Inject]." if annotated_ctors.size > 1 %}
                  {% raise "HardWire/UnknownConstructor: target: #{path}. Annotate your injectable constructor with @[HardWire::Inject]" if annotated_ctors.size < 1 %}
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

                    {% if !REGISTRATIONS.any? {|x| x[:type] == dependency_type.name.stringify && x[:tag] == dependency_tag } %}
                      {% raise "HardWire/MissingDependency: unabled to register #{register_type.id}, missing dependency #{arg.name}: #{dependency_type}[#{dependency_tag.id}]" %}
                    {% end %}

                    {% if [:transient, :singleton].includes?(lifecycle) && REGISTRATIONS.any? {|x| x[:type] == dependency_type.name.stringify && x[:tag] == dependency_tag && x[:lifecycle] == :scoped} %}
                      {% raise "HardWire/DependsOnScoped: unabled to register #{register_type.id}, cross-scoped dependency #{arg.name}: #{dependency_type}[#{dependency_tag.id}]" %}
                    {% end %}

                    {% if flag? :debug %}
                      {% puts "% NestedDependency: #{arg.name}: #{dependency_type}[#{dependency_tag.id}]" %}
                    {% end %}
                    {{dependency_name}}: self.resolve!(
                      type: {{dependency_type}},
                      tag: {{dependency_tag}},
                      scope: scope
                    ),
                  {% end %}
                {% end %}
              )
            {% end %}

            if lifecycle_required
              @@instances_{{register_type_safe.id}}[scope] ||= Hash(String, {{register_type.id}}).new
              @@instances_{{register_type_safe.id}}[scope][tag] = tempvar
            end

            return tempvar
          end
        {% end %}
        {% REGISTRATIONS << {type: register_type.stringify, tag: register_tag, lifecycle: lifecycle} %}
        
        # Interrogate the container to determine whether a scope has been initialized
        # NOTE: this only works if something has been resolved in scope before this method is called
        def self.has_scope?(scope_name) : Bool
          {% for registration in REGISTRATIONS %}
            {% registration_type_safe = registration[:type].gsub(/[^\w]/, "_") %}
            if @@instances_{{registration_type_safe.id}}.has_key? scope_name
              return true
            end
          {% end %}
          return false
        end

        # Destroy a scope's instances, leaving it able to be garbage collected
        def self.destroy_scope(scope_name)
          {% for registration in REGISTRATIONS %}
            {% registration_type_safe = registration[:type].gsub(/[^\w]/, "_") %}
            @@instances_{{registration_type_safe.id}}.delete scope_name
          {% end %}
        end
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
