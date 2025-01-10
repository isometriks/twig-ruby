# twig-ruby

Implementation of [Twig](https://twig.symfony.com/) in Ruby.

```bash
bundle add twig-ruby
```

## Rails

This gem includes a Railtie that will automatically add your views folder and
register a `:twig` template handler. Just simply create your views such as
`app/views/welcome/index.html.twig` and it will start rendering them.

Layouts currently do not work with this library, and probably aren't needed
since each template can choose which "layout" to use by using the `extends` tag:

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
