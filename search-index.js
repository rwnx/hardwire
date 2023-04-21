crystal_doc_search_index_callback({"repository_name":"hardwire","body":"# HardWire ⚡\n[![Crystal CI](https://github.com/rwnx/hardwire/workflows/Crystal%20CI/badge.svg?branch=master)](https://github.com/rwnx/hardwire/actions?query=workflow%3A%22Crystal+CI%22)\n\nA Compile-time Dependency Injection system for Crystal.\n\n## Installation\n\n1. Add the dependency to your `shard.yml`:\n\n```yaml\ndependencies:\n  hardwire:\n    github: rwnx/hardwire\n```\n\n2. Run `shards install`\n\n## Usage\n\n```crystal\nrequire \"hardwire\"\n```\n\nHardwire is designed to operate inside a container object.\nSince the resolution is compile-time (Using Macros), normally this will be a module.\n\n### Creating a container 📦\n```crystal\n# To create a new container, include `HardWire::Container`\n# This will add the macros you need to register and resolve wiring\nmodule Container\n  include HardWire::Container\n\n  # use transient/singleton to wire different lifecycles\n  # singleton dependencies will be memoized\n  # dependencies for the constructor will be resolved from the constructor automatically\n  transient Dependency\n  singleton NeedsDependency\n  scoped Webservice\n\n  # you can also register dependencies with a block instead of inspecting the constructor\n  # Your block MUST return an instance of the class you are registering\n  singleton NeedsDependency {\n    NeedsDependency.new( self.resolve Dependency )\n  }\nend\n```\n\nHardwire tries to operate with minimal modifications to other classes (unless required).\n_\"simple\"_ classes, e.g.\n  * Have a single constructor\n  * Have unique dependencies/do not require tags\n\nIf your classes match this signature, you can wire up in the container without adding anything to the classes.\n\nFor everything else, there's:\n\n### Multiple Constructors 🚧\nHardwire needs to know which constuctor function to use.\n\nAnnotate your \"Injectable\" constructor with the Hardwire::Inject annotation.\n```crystal\nclass MultipleInits\n  @[HardWire::Inject]\n  def initialize(input: String)\n    # register will inspect this method's arguments\n    # [...]\n  end\n\n  def initialize\n    # will not be used for injection\n    # [...]\n  end\nend\n```\n\n### Tags 🏷\nTo differentiate between registrations of _the same type_, use the HardWire::Tags annotation.\nTags allow you to attach additional metadata to the signature. Tags themselves are string-based, simple identifiers (/\\w+/) that allow you to resolve\na different registration of the same class.\n\n\n```crystal\n# [...]\n\n# registering a transient dependency with tag \"secret\"\ntransient String, \"secret\" {\n  \"a secret string\"\n}\n\n# registering a singleton\n# When no tags are set, it is considered the \"default\" registration\nsingleton DbService\n\n# registering a different singleton with a tag\nsingleton DbService, \"primary\"\n\n# Resolving Dependencies\nclass Resolving\n  @[Hardwire::Tags(input: \"secret\", primary_db: \"primary\")]\n  def initialize(input : String, primary_db : DbService, default_db : DbService)\n  end\nend\n```\n### Lifecycles ♽\nThere are 3 lifecycles available for registrations:\n* Singleton: The dependency is instantiated once for the lifetime of the application\n* Scoped: the dependency instantiated once for each created scope and destroyed when the scope is garbage-collected\n* Transient: the dependency is instatiated each time it is resolved\n\n#### Scopes 🔭\nTo managed scoped instances, you should create a scope object with the `.scope` macro.\n\n```crystal\n# This example will init a database DatabaseConnection for each http request\n# but all the databases will recieve the same instance of config (singleton)\n# the ScopedLogging dependency will also be instantiated once for each scope resolution\nrequire \"kemal\"\nclass Config; end\nclass ScopedLogging; end\nclass DatabaseConnection\n  def initialize(@config : Config, @logging : ScopedLogging)\n  end\nend\n\nmodule Container\n  include HardWire::Container\n\n  singleton Config\n  scoped ScopedLogging\n  scoped DatabaseConnection\nend\n\n\nget \"/\" do\n  # create a unique scope\n  scope = Container.scope\n\n  logger = scope.resolve ScopedLogging\n  db = scope.resolve DatabaseConnection\n  db.get_some_data\n\n  logger.log(\"I share a logger with the database in scope!\")\nend\n\nKemal.run\n\n```\n\n### Resolving Manually 🔨\nYou can resolve dependencies manually using the `.resolve` macro. This allows you to resolve dependencies manually with the tag string.\n\n```crystal\nmodule Container\n  include HardWire::Container\n\n  transient SecretService, \"primary\"\n  singleton DatabaseThing\nend\n\nservice = Container.resolve SecretService, \"primary\"\ndb = Container.resolve DatabaseThing\n```\n\n### Runtime Interrogation 👀\nHardwire can tell you information about the registrations at runtime, but the dependencies are _HardWired_ (See what I did there?), so they can't be changed.\n\n```crystal\nmodule Container\n  include HardWire::Container\n\n  singleton DbService\nend\n\nContainer.registered?(DbService) # true\nContainer.registered?(DbService, \"tagged\") # false\nContainer.registered?(String) # false\n```\n\n## Contributing\n\n1. Fork it (<https://github.com/rwnx/hardwire/fork>)\n2. Create your feature branch (`git checkout -b my-new-feature`)\n3. Commit your changes (`git commit -am 'Add some feature'`)\n4. Push to the branch (`git push origin my-new-feature`)\n5. Create a new Pull Request\n\n## Contributors\n\n- [rwnx](https://github.com/rwnx) - creator and maintainer\n","program":{"html_id":"hardwire/toplevel","path":"toplevel.html","kind":"module","full_name":"Top Level Namespace","name":"Top Level Namespace","abstract":false,"locations":[],"repository_name":"hardwire","program":true,"enum":false,"alias":false,"const":false,"types":[{"html_id":"hardwire/HardWire","path":"HardWire.html","kind":"module","full_name":"HardWire","name":"HardWire","abstract":false,"locations":[{"filename":"src/hardwire.cr","line_number":4,"url":null}],"repository_name":"hardwire","program":false,"enum":false,"alias":false,"const":false,"doc":"A Compile-time non-intrusive dependency injection system for Crystal.","summary":"<p>A Compile-time non-intrusive dependency injection system for Crystal.</p>","types":[{"html_id":"hardwire/HardWire/Container","path":"HardWire/Container.html","kind":"module","full_name":"HardWire::Container","name":"Container","abstract":false,"locations":[{"filename":"src/hardwire.cr","line_number":46,"url":null}],"repository_name":"hardwire","program":false,"enum":false,"alias":false,"const":false,"including_types":[{"html_id":"hardwire/HardWire/Root","kind":"module","full_name":"HardWire::Root","name":"Root"}],"namespace":{"html_id":"hardwire/HardWire","kind":"module","full_name":"HardWire","name":"HardWire"},"doc":"A module mixin for creating a hardwire container.\n\nNo functionality-based documentation will appear here, since the module is designed to be included\nin other modules. See `HardWire::Root` for container-level functionality.\n```\nmodule WhateverYouLikeContainer\n  include Hardwire::Container\nend\n```","summary":"<p>A module mixin for creating a hardwire container.</p>"},{"html_id":"hardwire/HardWire/Inject","path":"HardWire/Inject.html","kind":"annotation","full_name":"HardWire::Inject","name":"Inject","abstract":false,"locations":[{"filename":"src/hardwire.cr","line_number":34,"url":null}],"repository_name":"hardwire","program":false,"enum":false,"alias":false,"const":false,"namespace":{"html_id":"hardwire/HardWire","kind":"module","full_name":"HardWire","name":"HardWire"},"doc":"Attach this annotation to a #initialize function in a multi-constructor class\nto indicate that it is to be used for dependency injection.\n\nThis annotation is not required when a class has one constructor only.\n```\ndef initialize\n  # wont be used\nend\n\n@[HardWire::Inject]\ndef initialize\n  # will be used\nend\n```","summary":"<p>Attach this annotation to a #initialize function in a multi-constructor class to indicate that it is to be used for dependency injection.</p>"},{"html_id":"hardwire/HardWire/Root","path":"HardWire/Root.html","kind":"module","full_name":"HardWire::Root","name":"Root","abstract":false,"ancestors":[{"html_id":"hardwire/HardWire/Container","kind":"module","full_name":"HardWire::Container","name":"Container"}],"locations":[{"filename":"src/hardwire.cr","line_number":318,"url":null}],"repository_name":"hardwire","program":false,"enum":false,"alias":false,"const":false,"constants":[{"id":"REGISTRATIONS","name":"REGISTRATIONS","value":"[] of NamedTuple(type: String, tag: String, lifecycle: Symbol)","doc":"Store all registrations, which are mainly used to give nice errors for duplicate registrations\n\nUsers can also run their own checks at runtime for length, structure, etc.","summary":"<p>Store all registrations, which are mainly used to give nice errors for duplicate registrations</p>"}],"included_modules":[{"html_id":"hardwire/HardWire/Container","kind":"module","full_name":"HardWire::Container","name":"Container"}],"namespace":{"html_id":"hardwire/HardWire","kind":"module","full_name":"HardWire","name":"HardWire"},"doc":"A pre-made Container, designed to provide a concrete in-namespace module to generate documentation from.\n\nNOTE: All of the methods in this library are designed to operate _inside_ the container class,\nso you cannot use this container for actual dependency injection","summary":"<p>A pre-made Container, designed to provide a concrete in-namespace module to generate documentation from.</p>","class_methods":[{"html_id":"registered?(target:Class,tag=\"default\"):Bool-class-method","name":"registered?","doc":"Interrogate the container for a registration","summary":"<p>Interrogate the container for a registration</p>","abstract":false,"args":[{"name":"target","external_name":"target","restriction":"Class"},{"name":"tag","default_value":"\"default\"","external_name":"tag","restriction":""}],"args_string":"(target : Class, tag = \"default\") : Bool","args_html":"(target : Class, tag = <span class=\"s\">&quot;default&quot;</span>) : Bool","location":{"filename":"src/hardwire.cr","line_number":319,"url":null},"def":{"name":"registered?","args":[{"name":"target","external_name":"target","restriction":"Class"},{"name":"tag","default_value":"\"default\"","external_name":"tag","restriction":""}],"return_type":"Bool","visibility":"Public","body":"return REGISTRATIONS.any? do |x|\n  (x[:type] == target.name) && (x[:tag] == tag)\nend"}}],"macros":[{"html_id":"resolve(target,tag=\"default\")-macro","name":"resolve","doc":"Resolve a dependency from a class and a string tag\n\nThis macro does the legwork of mangling the dynamic-looking call into the statically-defined `resolve!` method\n\nNOTE: This method does not protect you from unregistered dependencies, since it relies on\ndirectly resolving the `resolve!` method. If you need safety - use `registered?`","summary":"<p>Resolve a dependency from a class and a string tag</p>","abstract":false,"args":[{"name":"target","external_name":"target","restriction":""},{"name":"tag","default_value":"\"default\"","external_name":"tag","restriction":""}],"args_string":"(target, tag = \"default\")","args_html":"(target, tag = <span class=\"s\">&quot;default&quot;</span>)","location":{"filename":"src/hardwire.cr","line_number":319,"url":null},"def":{"name":"resolve","args":[{"name":"target","external_name":"target","restriction":""},{"name":"tag","default_value":"\"default\"","external_name":"tag","restriction":""}],"visibility":"Public","body":"        HardWire::Root.resolve!(\n{{ target }}\n, \n{{ tag }}\n)\n      \n"}},{"html_id":"scope(name)-macro","name":"scope","doc":"create a new scope with the specified name","summary":"<p>create a new scope with the specified name</p>","abstract":false,"args":[{"name":"name","external_name":"name","restriction":""}],"args_string":"(name)","args_html":"(name)","location":{"filename":"src/hardwire.cr","line_number":319,"url":null},"def":{"name":"scope","args":[{"name":"name","external_name":"name","restriction":""}],"visibility":"Public","body":"        HardWire::Root::Scope.new(\n{{ name }}\n)\n      \n"}},{"html_id":"scope-macro","name":"scope","doc":"Create a new scope with a randomly chosen unique ID","summary":"<p>Create a new scope with a randomly chosen unique ID</p>","abstract":false,"location":{"filename":"src/hardwire.cr","line_number":319,"url":null},"def":{"name":"scope","visibility":"Public","body":"        HardWire::Root::Scope.new(UUID.random.to_s)\n      "}},{"html_id":"scoped(path,tag=nil,&block)-macro","name":"scoped","doc":"Register a scoped dependency.","summary":"<p>Register a scoped dependency.</p>","abstract":false,"args":[{"name":"path","external_name":"path","restriction":""},{"name":"tag","default_value":"nil","external_name":"tag","restriction":""}],"args_string":"(path, tag = nil, &block)","args_html":"(path, tag = <span class=\"n\">nil</span>, &block)","location":{"filename":"src/hardwire.cr","line_number":319,"url":null},"def":{"name":"scoped","args":[{"name":"path","external_name":"path","restriction":""},{"name":"tag","default_value":"nil","external_name":"tag","restriction":""}],"block_arg":{"name":"block","external_name":"block","restriction":""},"visibility":"Public","body":"        \n{% if block %}\n          register {{ path }}, :scoped, {{ tag }} {{ block }}\n        {% else %}\n          register {{ path }}, :scoped, {{ tag }}\n        {% end %}\n\n      \n"}},{"html_id":"scoped(path,&block)-macro","name":"scoped","doc":"Register a singleton dependency.","summary":"<p>Register a singleton dependency.</p>","abstract":false,"args":[{"name":"path","external_name":"path","restriction":""}],"args_string":"(path, &block)","args_html":"(path, &block)","location":{"filename":"src/hardwire.cr","line_number":319,"url":null},"def":{"name":"scoped","args":[{"name":"path","external_name":"path","restriction":""}],"block_arg":{"name":"block","external_name":"block","restriction":""},"visibility":"Public","body":"          singleton(\n{{ path }}\n) \n{{ block }}\n\n      \n"}},{"html_id":"singleton(path,tag=nil,&block)-macro","name":"singleton","doc":"Register a singleton dependency.","summary":"<p>Register a singleton dependency.</p>","abstract":false,"args":[{"name":"path","external_name":"path","restriction":""},{"name":"tag","default_value":"nil","external_name":"tag","restriction":""}],"args_string":"(path, tag = nil, &block)","args_html":"(path, tag = <span class=\"n\">nil</span>, &block)","location":{"filename":"src/hardwire.cr","line_number":319,"url":null},"def":{"name":"singleton","args":[{"name":"path","external_name":"path","restriction":""},{"name":"tag","default_value":"nil","external_name":"tag","restriction":""}],"block_arg":{"name":"block","external_name":"block","restriction":""},"visibility":"Public","body":"        \n{% if block %}\n          register {{ path }}, :singleton, {{ tag }} {{ block }}\n        {% else %}\n          register {{ path }}, :singleton, {{ tag }}\n        {% end %}\n\n      \n"}},{"html_id":"singleton(path,&block)-macro","name":"singleton","doc":"Register a singleton dependency.","summary":"<p>Register a singleton dependency.</p>","abstract":false,"args":[{"name":"path","external_name":"path","restriction":""}],"args_string":"(path, &block)","args_html":"(path, &block)","location":{"filename":"src/hardwire.cr","line_number":319,"url":null},"def":{"name":"singleton","args":[{"name":"path","external_name":"path","restriction":""}],"block_arg":{"name":"block","external_name":"block","restriction":""},"visibility":"Public","body":"          singleton(\n{{ path }}\n) \n{{ block }}\n\n      \n"}},{"html_id":"transient(path,tag=nil,&block)-macro","name":"transient","doc":"Register a transient dependency.","summary":"<p>Register a transient dependency.</p>","abstract":false,"args":[{"name":"path","external_name":"path","restriction":""},{"name":"tag","default_value":"nil","external_name":"tag","restriction":""}],"args_string":"(path, tag = nil, &block)","args_html":"(path, tag = <span class=\"n\">nil</span>, &block)","location":{"filename":"src/hardwire.cr","line_number":319,"url":null},"def":{"name":"transient","args":[{"name":"path","external_name":"path","restriction":""},{"name":"tag","default_value":"nil","external_name":"tag","restriction":""}],"block_arg":{"name":"block","external_name":"block","restriction":""},"visibility":"Public","body":"        \n{% if block %}\n          register {{ path }}, :transient, {{ tag }} {{ block }}\n        {% else %}\n          register {{ path }}, :transient, {{ tag }}\n        {% end %}\n\n      \n"}},{"html_id":"transient(path,&block)-macro","name":"transient","doc":"Register a transient dependency.","summary":"<p>Register a transient dependency.</p>","abstract":false,"args":[{"name":"path","external_name":"path","restriction":""}],"args_string":"(path, &block)","args_html":"(path, &block)","location":{"filename":"src/hardwire.cr","line_number":319,"url":null},"def":{"name":"transient","args":[{"name":"path","external_name":"path","restriction":""}],"block_arg":{"name":"block","external_name":"block","restriction":""},"visibility":"Public","body":"        transient(\n{{ path }}\n) \n{{ block }}\n\n      \n"}}],"types":[{"html_id":"hardwire/HardWire/Root/Scope","path":"HardWire/Root/Scope.html","kind":"class","full_name":"HardWire::Root::Scope","name":"Scope","abstract":false,"superclass":{"html_id":"hardwire/Reference","kind":"class","full_name":"Reference","name":"Reference"},"ancestors":[{"html_id":"hardwire/Reference","kind":"class","full_name":"Reference","name":"Reference"},{"html_id":"hardwire/Object","kind":"class","full_name":"Object","name":"Object"}],"locations":[{"filename":"src/hardwire.cr","line_number":319,"url":null}],"repository_name":"hardwire","program":false,"enum":false,"alias":false,"const":false,"namespace":{"html_id":"hardwire/HardWire/Root","kind":"module","full_name":"HardWire::Root","name":"Root"},"doc":"A Scope is an object that represents the a scope's lifecycle\n\nIt is a a helper class for accessing scoped resolution\nand providing a lifecycle hook to destroy/garbage collect the scoped instances\n\nScopes work in exactly the same way that singleton lifecycles do, except that the user has control\nover when the instances stored inside are released for garbage collection.\n\nNOTE: you should not construct these directly, instead prefering to use the `.scope` macro on the container module","summary":"<p>A Scope is an object that represents the a scope's lifecycle</p>","constructors":[{"html_id":"new(name:String)-class-method","name":"new","abstract":false,"args":[{"name":"name","external_name":"name","restriction":"String"}],"args_string":"(name : String)","args_html":"(name : String)","location":{"filename":"src/hardwire.cr","line_number":319,"url":null},"def":{"name":"new","args":[{"name":"name","external_name":"name","restriction":"String"}],"visibility":"Public","body":"_ = allocate\n_.initialize(name)\nif _.responds_to?(:finalize)\n  ::GC.add_finalizer(_)\nend\n_\n"}}],"instance_methods":[{"html_id":"destroy-instance-method","name":"destroy","doc":"Destroy the represented scope and release the instances for garbage collection\n\nNOTE: this will be called when the scope itself is garbage-collected","summary":"<p>Destroy the represented scope and release the instances for garbage collection</p>","abstract":false,"location":{"filename":"src/hardwire.cr","line_number":319,"url":null},"def":{"name":"destroy","visibility":"Public","body":"HardWire::Root.destroy_scope(@name)"}},{"html_id":"finalize-instance-method","name":"finalize","abstract":false,"location":{"filename":"src/hardwire.cr","line_number":319,"url":null},"def":{"name":"finalize","visibility":"Public","body":"self.destroy"}},{"html_id":"name:String-instance-method","name":"name","abstract":false,"def":{"name":"name","visibility":"Public","body":"@name"}},{"html_id":"resolve(target:Class,tag=\"default\")-instance-method","name":"resolve","doc":"Resolve a dependency from the represented scope","summary":"<p>Resolve a dependency from the represented scope</p>","abstract":false,"args":[{"name":"target","external_name":"target","restriction":"Class"},{"name":"tag","default_value":"\"default\"","external_name":"tag","restriction":""}],"args_string":"(target : Class, tag = \"default\")","args_html":"(target : Class, tag = <span class=\"s\">&quot;default&quot;</span>)","location":{"filename":"src/hardwire.cr","line_number":319,"url":null},"def":{"name":"resolve","args":[{"name":"target","external_name":"target","restriction":"Class"},{"name":"tag","default_value":"\"default\"","external_name":"tag","restriction":""}],"visibility":"Public","body":"HardWire::Root.resolve!(target, tag, scope: @name)"}}]}]},{"html_id":"hardwire/HardWire/Tags","path":"HardWire/Tags.html","kind":"annotation","full_name":"HardWire::Tags","name":"Tags","abstract":false,"locations":[{"filename":"src/hardwire.cr","line_number":17,"url":null}],"repository_name":"hardwire","program":false,"enum":false,"alias":false,"const":false,"namespace":{"html_id":"hardwire/HardWire","kind":"module","full_name":"HardWire","name":"HardWire"},"doc":"Attach this annotation to a #initialize function to indicate which tags this method needs to resolve\nfor each dependency.\n\nThis annotation takes a key-value set of arguments matching argument names to tags.\n```\n# resolve the db_service with tag \"secondary\"\n@[HardWire::Tags(db_service: \"secondary\")]\ndef initialize(db_service : DbService)\n```","summary":"<p>Attach this annotation to a #initialize function to indicate which tags this method needs to resolve for each dependency.</p>"}]}]}})