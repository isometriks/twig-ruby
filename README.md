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
- [Things to Know](#things-to-know)
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
  config.twig.cache = ::Rails.root.join('tmp/cache/twig', ::Rails.env).to_s
  config.twig.charset = 'UTF-8'
  config.twig.strict_variables = true
  config.twig.autoescape = ->(name) { ::Twig::Rails::EscapingStrategy.guess(name) }
  config.twig.auto_reload = !::Rails.env.production?
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

Rails helpers can also be called. Parenthesis is only required when passing arguments:

```twig
{{ stylesheet_link_tag(:app, "data-turbo-track": "reload") }}
{{ javascript_importmap_tags }}
```

Names can end in `?` like Ruby predicates, so these helpers can be called bare too:

```twig
{% if user_signed_in? and not current_user.admin? %}...{% endif %}
{% if current_page?(root_path) %}...{% endif %}
```

The `?` stays on the name when what follows it couldn't start an expression: the end of
the tag, `)`, `]`, `}`, `,`, `|`, a `:` that isn't a symbol, another `?`, or an operator
like `and` or `==`.
Anything else makes it the ternary operator, as in Twig PHP, so `{{ ready?1:2 }}`,
`{{ ready? 'yes' : 'no' }}` and `{{ ready? :yes : :no }}` are ternaries on `ready`, and
`ready?:b` and `ready??b` are still the `?:` and `??` operators.

A mapping key keeps its `?` before the colon, so `{open?: true}` has the key `open?`.
An attribute keeps it before `-`, `+`, `[` or `(`, which could go on with the attribute, so
`user.admin? - 1` and `user.roles?[0]` read `admin?` and `roles?`. Write
`user.admin ? -1` if you mean a ternary there. Arrow function and macro arguments can't end
in `?`.

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

## Things to Know

These all work as intended, most of them just as in Twig PHP, but they can still catch you out.

**A newline straight after a tag is removed.** `{{ name }}{% if address %}` followed by a
newline and `{{ address }}{% endif %}` renders the two values with nothing between them.
Whitespace control can only take whitespace away, never add it, so leave a blank line after
the tag (the second newline is kept) or print one with `{{ "\n" }}`.

**`empty` is a test, not a filter.** Write `{% if items is not empty %}`; `items|empty` is a
syntax error. The test also handles `nil`, where `items.any?` would raise "Impossible to
access an attribute on a null variable".

**`strict_variables` raises on missing keys.** The Rails config turns it on, so
`{{ params[:page] }}` raises when there's no `page` param. `??` and `default` are the way
to allow for it:

```twig
{{ params[:page] ?? 1 }}
{{ params[:q]|default('') }}
```

**Controller methods need `helper_method`.** A name that isn't in the template's context is
looked up on the view, which only sees public helpers. A controller method a template calls
has to be exposed the same way it would be for ERB:

```ruby
class ApplicationController < ActionController::Base
  helper_method :current_account
end
```

**Text templates aren't escaped in Rails.** The default `autoescape` picks a strategy from
the template name: HTML for `.html.twig`, JavaScript for `.js.twig` and `.json.twig`, CSS
for `.css.twig`, and none for `.text.twig` (Rails' name for plain text, as in a mailer's
`welcome.text.twig`) or `.txt.twig`. Set `config.twig.autoescape = :name` to use Twig PHP's
own guess, which only knows `txt`.

**Clear `tmp/cache/twig` after editing your own `autoescape` lambda.** Escaping is decided
when a template is compiled. The compiled cache is keyed by the template's name, the gem's
version and source, the extensions, and the `debug`, `strict_variables`,
`allow_helper_methods` and `autoescape` options, so upgrading the gem or changing those
options compiles every template again. A lambda is keyed by the file and line it's defined
on, though, so when you change what your lambda returns without moving it, a template
compiled under the old one keeps its escaping until its cache file is removed.

**Compiled templates are checked for edits everywhere but production.** They're cached in
`tmp/cache/twig/<env>`, which outlives the process, so `auto_reload` is on in development
and test, and a test run after an edit picks the edit up. Each environment has its own
directory, so a test run never replaces what the dev server compiled. In production the
cache is trusted without a check, so start each deploy with an empty `tmp/cache/twig`.
