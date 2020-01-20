# TODO: Write documentation for `HardWire`

module HardWire
  VERSION = "0.1.0"

  # provides a symbol: String mapping of argument names(dependencies) to tags in a string-csv format
  # e.g.   @[HardWire::Tags(db_service: "secondary,primary")]
  # tags are in AND-logic, so services need ALL tags to resolve.
  annotation Tags
  end

  # indicates a single constuctor to be used as the injection interface,
  # When there are many constructors to choose from
  # This is not required when there is only one constructor
  annotation Inject
  end

  class AlreadyRegisteredException < Exception
    def initialize(@path : Symbol, @lifecycle : Symbol, @tags = [] of Symbol)
      super("Failed to register new #{@lifecycle}, #{@path}#{@tags} Already registered")
    end
  end

  module Container
    macro included
      # Store all registered deps, which are used to give nice errors for duplicate registrations
      @@registrations = [] of String
      class_getter registrations

      def self.registered?(type : Class, tags : String)
        tagstring = "_" + tags.strip.split(",").map(&.strip).map(&.downcase).sort.join("_") 
        return @@registrations.any? { |e| e == type.name + tagstring}
      end

      def self.registered?(type : Class)
        return @@registrations.any? { |e| e == type.name }
      end

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
          raise ::HardWire::AlreadyRegisteredException.new( path: :\{{selftype.id}},
            lifecycle: \{{lifecycle}},
            \{% if regtags.size > 0 %}
              tags:
                [\{% for tag in regtags %} :\{{tag.id}},\{% end %}]
              \{% end %}
            )
        end

        # For use in type signatures, define a new type for this dependencies tags
        module Tags
          module \{{selftype.id}}
            \{% for tag in regtags %}
              class \{{tag.upcase.id}}
              end
            \{% end %}
          end
        end

        # Resolve is overloaded with each registed class + tags combo
        def self.resolve( type : \{{selftype.class}},  \{% for tag in regtags %} \{{tag.downcase.id}} : Tags::\{{selftype.id}}::\{{tag.upcase.id}}.class, \{% end %} ) : \{{selftype.id}}
          # Singletons: memoize to class var
          \{% if lifecycle == :singleton %}
            @@\{{selftype.id}}\{%for tag in regtags %}_\{{tag.id}}\{% end %} ||=
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
                      \{{tag}}: Tags::\{{arg.restriction.id}}::\{{tag.upcase.id}},
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

      # convenience methods for lifecycles
      macro transient(path, tags = nil, &block)
        \{% if block %}
          register \{{path}}, :transient, \{{tags}} \{{block}}
        \{% else %}
          register \{{path}}, :transient, \{{tags}}
        \{% end %}
      end

      macro singleton(path, tags = nil, &block)
        \{% if block %}
          register \{{path}}, :singleton, \{{tags}} \{{block}}
        \{% else %}
          register \{{path}}, :singleton, \{{tags}}
        \{% end %}
      end

      macro transient(path, &block)
          transient(\{{path}}) \{{block}}
      end

      macro singleton(path, &block)
          singleton(\{{path}}) \{{block}}
      end
    end
  end
end
