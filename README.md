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

or cache

```twig
{% yield cache(product) do %}
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
