# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'twig_ruby'
  s.version     = '0.0.2'
  s.summary     = 'Twig Templating for Ruby'
  s.description = ''
  s.authors     = ['Craig Blanchette', 'Fabian Potencier']
  s.email       = 'craig.blanchette@gmail.com'
  s.files       = Dir['lib/**/*']
  s.homepage    = 'https://rubygems.org/gems/twig-ruby'
  s.license     = 'MIT'
  s.metadata['rubygems_mfa_required'] = 'true'
  s.required_ruby_version = '>= 3.4'
  s.add_dependency 'activesupport'
  s.add_dependency 'sanitize'
end
