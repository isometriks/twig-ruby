# twig-ruby

Implementation of [Twig](https://twig.symfony.com/) in Ruby.

```bash
bundle add twig-ruby
```

## Rails

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

You should add `layout false` in your `ApplicationController`

```ruby
class ApplicationController < ActionController::Base
  layout false
end
```

## Rails Configuration

These are all the defaults. You only need this configuration if you plan to change anything. 

```ruby
Rails.application.configure do
  config.twig.root = ::Rails.root, # Used for default Filesystem Loader
  config.twig.paths = %w[/ app/views/], # Used for default Filesystem Loader
  config.twig.debug = ::Rails.env.development?,
  config.twig.allow_helper_methods = true,
  config.twig.cache = ::Rails.root.join('tmp/cache/twig').to_s,
  config.twig.charset = 'UTF-8',
  config.twig.strict_variables = true,
  config.twig.auto_reload = nil,
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

## Additions

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
{% endyield %}
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
