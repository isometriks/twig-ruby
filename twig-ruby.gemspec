# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'twig_ruby'
  s.version     = '0.0.4'
  s.summary     = 'Twig Templating for Ruby'
  s.description = ''
  s.authors     = ['Craig Blanchette', 'Fabian Potencier']
  s.email       = 'craig.blanchette@gmail.com'
  s.files       = Dir[
    'README.md',
    'lib/**/*'
  ]

  s.metadata['allowed_push_host'] = 'https://rubygems.org'
  s.metadata['rubygems_mfa_required'] = 'true'
  s.metadata['source_code_uri'] = 'https://github.com/isometriks/twig-ruby'

  s.homepage    = 'https://rubygems.org/gems/twig-ruby'
  s.license     = 'BSD-3-Clause'
  s.required_ruby_version = '>= 3.4'
  s.add_dependency 'activesupport'
  s.add_dependency 'sanitize'
end
