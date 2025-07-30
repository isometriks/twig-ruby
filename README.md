# twig-ruby

Implementation of [Twig](https://twig.symfony.com/) in Ruby.

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Template Features](#template-features)
  - [Filters](#filters)
  - [Functions](#functions)
  - [Tests](#tests)
  - [Tags](#tags)
- [Rails Integration](#rails-integration)
- [Advanced Features](#advanced-features)
- [Configuration](#configuration)
- Advanced Docs
  - [Loaders](doc/loaders.md)
  - [Extensions](doc/extensions.md)

## Installation

```bash
bundle add twig_ruby
```

## Quick Start

Here's a simple example to get you started:

```ruby
require 'twig_ruby'

# Create a loader with your templates
loader = Twig::Loader::Hash.new({
  'hello.twig' => 'Hello {{ name }}!'
})

# Create environment and render
environment = Twig::Environment.new(loader)
template = environment.load('hello.twig')
puts template.render({ name: "World" })
# Output: Hello World!
```

Or from your file system:

```ruby
loader = Twig::Loader::Filesystem.new(__dir__, ['app/views'])
```

## Template Features

Twig has the notion of Filters, Functions, and Tests

### Filters

Filters are used to modify variables.

```twig
{{ "hello"|capitalize }} {# Hello #}
{{ ["Hello", "World"]|join(" ") }} {# Hello World #}
```

### Functions

Functions are used to generate content.

```twig
{{ max([1, 2, 3]) }} {# 3 #}
{{ include("other.twig") }} {# contents of other.twig #}
```

### Tests

Tests are used to evaluate variables.

```twig
{{ 2 is even ? 'yup' : 'nope' }} {# yup #}
{{ ([1, 2, 3] has some n => n % 2 == 0) ? 'yup' : 'nope' }} {# yup #}
```

### Tags

Tags are used to control the logic of the template.

```twig
{% if n > 1 %}
  Some
{% else %}
  None
{% endif %}
```

```twig
<ul>
  {% for i in [1, 2, 3] %}
    <li>Item {{ i }}</li>
  {% endfor %}
</ul>
```

## Rails Integration

This gem includes a Railtie that will automatically add your views folder and
register a `:twig` template handler. Just simply create your views such as
`app/views/welcome/index.html.twig` and it will start rendering them.

```twig
{# welcome/index.html.twig #}

{% extends 'base.html.twig' %}

{% block body %}
  Welcome to my site!
{% endblock %}
```

Since Twig supports layouts through template inheritance (which is more flexible than Rails layouts),
you'll typically want to use Twig's inheritance system instead of Rails layouts. This allows you to:

1. Create a base template with common structure
2. Override specific blocks in child templates
3. Nest layouts for more complex page structures

To use Twig's inheritance instead of Rails layouts, disable Rails layouts in your controller:

```ruby
class ApplicationController < ActionController::Base
  layout false
end
```

## Configuration

These are all the defaults. You only need this configuration if you plan to change anything. 

```ruby
Rails.application.configure do
  config.twig.root = ::Rails.root # Used for default Filesystem Loader
  config.twig.paths = %w[/ app/views/] # Used for default Filesystem Loader
  config.twig.debug = ::Rails.env.development?
  config.twig.allow_helper_methods = true
  config.twig.cache = ::Rails.root.join('tmp/cache/twig').to_s
  config.twig.charset = 'UTF-8'
  config.twig.strict_variables = true
  config.twig.autoescape = :name
  config.twig.auto_reload = nil
  config.twig.loader = lambda do
    ::Twig::Loader::Filesystem.new(
      current.root,
      current.paths
    )
  end
end
```

The loader is memoized as late as possible, so if you need to actually access the loader instance, you can
use `Twig.loader` to create the instance. If you do this, you can no longer set a new loader with the config
or paths. You would need to use any available methods on the loader to alter it:

```ruby
config.after_initialize do
  Twig.loader.prepend_path('app/views/theme', 'theme')
end
```

If you plan to create your own loader that loads templates from another source like the database, you can provide
a different lamba in the config for initializing it. 

## Advanced Features

Twig Ruby supports symbols as Ruby does and can be used in places strings can as 
hash keys, arguments, etc.

```twig
{{ name[:first] }}
{{ user_func(:first, :second) }}
{% set hash = { key: :value } %}
```

Since Ruby has the concept of blocks, a new tag is introduced call `yield` it
can be used with helpers like `form_with`

```twig
{% yield form_with(url: 'login') do |f| %}
  {{ f.email_field(:email) }}
{% endyield %}
```
### Cache Tag

The way the `cache` tag works in Rails is that it captures output from the buffer that 
sends the contents of the response. Twig cannot do this prematurely since a cache might be used within
a block or other callable meant to return the string. There is a cache tag to handle this instead 
that is passed the same arguments it normally would, but has extra code to capture the cache. 
Using `{% yield cache() do %}` WILL NOT WORK CORRECTLY.

```twig
{% cache(product) %}
  ...
{% endcache %}
```

Macros can also use Ruby notation for default values:

Typical Twig:
```twig
{% macro input(name, value, type = "text", size = 20) %}
  <input type="{{ type }}" name="{{ name }}" value="{{ value|e }}" size="{{ size }}"/>
{% endmacro %}
```

Twig Ruby (Both versions work)
```twig
{% macro input(name, value, type: "text", size: 20) %}
  <input type="{{ type }}" name="{{ name }}" value="{{ value|e }}" size="{{ size }}"/>
{% endmacro %}
```
