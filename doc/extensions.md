# Extensions

Extensions are used to add functionality to Twig. The most common elements to add
through an extension are functions, filters, tests, and globals.

To create an extension, extend the `Twig::Extension::Base` class, which provides helpful shortcuts
for building extensions and implements empty methods for extension points you may not need.
This base class handles common boilerplate code so you can focus on implementing just the
functionality you need.

## Functions

All the callables can be setup as class methods, instance methods, or procs

### Class Method

```ruby
class UpperExtension < Twig::Extension::Base
  def functions
    [
      # The 'static' helper creates a callable reference to a class method
      # It's equivalent to self.class.method(:upper) but more concise
      Twig::TwigFunction.new('upper', static(:upper)),
    ]
  end
  
  def self.upper(value)
    value.upcase
  end
end
``` 

### Instance Method

```ruby
class UpperExtension < Twig::Extension::Base
  def functions
    [
      Twig::TwigFunction.new('upper', method(:upper)),
    ]
  end
  
  def upper(value)
    value.upcase
  end
end
``` 

### Proc

```ruby
class UpperExtension < Twig::Extension::Base
  def functions
    [
      Twig::TwigFunction.new('upper', ->(value) { value.upcase }),
    ]
  end
end
``` 

## Registering Extensions

After creating an extension, you need to register it with the Twig environment. There are several ways to do this:

### Per-Environment Registration

```ruby
# Create your environment
environment = Twig::Environment.new(loader)

# Add your extension
environment.add_extension(UpperExtension.new)
```

### Global Registration with Rails

In a Rails application, you can register extensions in an initializer:

```ruby
# config/initializers/twig.rb
Rails.application.config.to_prepare do
  Twig.environment.add_extension(UpperExtension.new)
  # Add other extensions as needed
end
```

Once registered, you can use your extension's functionality in templates:

```twig
{{ upper("hello world") }} {# HELLO WORLD #}
```

## Filters

Filters work the same way as functions do above in the previous section, just use `TwigFilter` instead:

```ruby
class UpperExtension < Twig::Extension::Base
  def filters
    [
      Twig::TwigFilter.new('upper', ->(value) { value.upcase }),
    ]
  end
end
``` 

```twig
{{ "hello world"|upper }} {# HELLO WORLD #}
```

## Tests

Tests also work as functions and filters do above

```ruby
class UpperExtension < Twig::Extension::Base
  def tests
    [
      Twig::TwigTest.new('upper', ->(value) { value.match?(/^[A-Z]+$/) }),
    ]
  end
end
``` 

```twig
{{ "hello" is upper ? 'yes' : 'no' }} {# no #}
{{ "HELLO" is upper ? 'yes' : 'no' }} {# yes #}
```

## Globals

Globals allow you to provide variables that are accessible in any template without needing to pass them explicitly in the context. This is useful for application-wide configuration values, constants, or commonly used data.

```ruby
class AppExtension < Twig::Extension::Base
  def globals
    {
      # Static configuration values
      ga_tracking: 'UA-xxxxx-x',
      app_version: '1.2.3',

      # Dynamic values
      current_year: Time.now.year,
      is_production: Rails.env.production?,

      # Helper methods/lambdas
      format_date: ->(date) { date.strftime('%B %d, %Y') }
    }
  end
end
```

Once registered, these globals can be used in any template:

```twig
<footer>
  © {{ current_year }} My Company | Version {{ app_version }}
  {% if is_production %}
    <!-- Analytics code: {{ ga_tracking }} -->
  {% endif %}

  <!-- Using a lambda global -->
  Last updated: {{ format_date.call(page.updated_at) }}
</footer>
```

Globals are especially useful for values that would otherwise need to be included in every template render call.
