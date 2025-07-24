# Loaders

## Hash Loader

Template names are keys, and their values are the template contents.

```ruby
loader = Twig::Loader::Hash.new({
  'template.twig' => '{{ var }}',
})
```

## Filesystem Loader

The filesystem loader accepts a base path, and then an array of paths
to look in relative to that:

```ruby
loader = Twig::Loader::Filesystem.new(__dir__, %w[views ui])
```

If the file you ran this in was at `/app` and you tried to load `index.html.twig'
it would first look to see if `/app/views/index.html.twig` existed, and then look
to see if `/app/ui/index.html.twig` exists and render it.

### Namespaces

The filesystem loader also supports namespaces:

```ruby
loader = Twig::Loader::Filesystem.new(...)
loader.add_path('themes/default', 'theme')
loader.add_path('themes/active', 'theme')
```

When using namespaces, you refer to them like `@theme` so as with the example above, if
you tried to load `@theme/index.html.twig` then it would look into `/app/themes/default/index.html.twig`
and then `/app/themes/active/index.html.twig`

Though, we probably want our active theme to take precedence over the default theme, in this case you can use
`prepend_path` so we could do `loader.prepend_path('themes/active', 'theme')` instead.

Of course, you also have `set_paths` if you wanted to set the paths exactly:

```ruby
loader = Twig::Loader::Filesystem.new(...)
loader.set_paths(%w[themes/active themes/default], 'theme')
```

## Chain Loader

The chain loader allows you to combine multiple loaders into one:

```ruby
first = Twig::Loader::Hash.new({ 'first.twig' => 'first' })
second = Twig::Loader::Hash.new({ 'second.twig' => 'second' })
chain = Twig::Loader::Chain.new([first, second])

env = Twig::Environment.new(chain)
env.load('first.twig')
env.load('second.twig')
```

## Creating your own loader

There is a base class that you can use if you'd like `Twig::Loader::Base` that has the methods
stubbed that are required: `get_source_context(name)`, `get_cache_key(name)`, `fresh?(name, time)` and
`exists?(name)`. Implementing a loader from the database might look something like this if you had
an ActiveRecord model named `Template`:

```ruby
class DatabaseLoader < Twig::Loader::Base
  def get_source_context(name)
    template = Template.find_by(name:)
    raise Twig::Error::Loader unless template

    ::Twig::Source.new(template.body, name)
  end
  
  def get_cache_key(name)
    template = Template.find_by(name:)
    raise Twig::Error::Loader unless template
    
    "#{template.id}:#{template.name}"
  end
  
  def fresh?(name, time)
    template = Template.find_by(name:)
    raise Twig::Error::Loader unless template

    template.updated_at.to_i < time
  end
  
  def exists?(name)
    !Template.find_by(name:).nil?
  end
end
```

There's a lot of oportunities to cache a lot of the database calls in the class above but it
is written for simplicity. 

## Template Reloading

The loaders will only use `fresh?` when the `auto_reload` option is set. If you are storing templates
in the database and want them to update automatically, then you would need this option set to true. 
For filesystem loaders in production you will almost always want `auto_reload` set to false for the
best performance.
