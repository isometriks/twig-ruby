# Extensions

Extensions are how to add functionality to Twig. The most common things to add
with an extension are functions, filters, tests, and globals. 

You can extend from `Twig::Extension::Base` which will give you some shortcuts 
for building an extension and already returns empty arrays / hashes for things
you may not want to implement. 

## Functions

All the callables can be setup as class methods, instance methods, or procs

### Class Method

```ruby
class UpperExtension < Twig::Extension::Base
  def functions
    [
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

Now you need to add the extension to the environment:

```ruby
environment.add_extension(UpperExtension.new)
```

And you can use it in your templates:

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

You can also provide global variables that can be accessed in any template without being passed

```ruby
class UpperExtension < Twig::Extension::Base
  def globals
    {
      ga_tracking: 'UA-xxxxx-x'
    }
  end
end
```

Now you can use `{{ ga_tracking }}` anywhere you'd like. 
