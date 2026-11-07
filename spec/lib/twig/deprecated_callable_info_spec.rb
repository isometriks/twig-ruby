# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::DeprecatedCallableInfo do
  let(:extension) do
    Class.new(Twig::Extension::Base) do
      def functions
        [
          Twig::TwigFunction.new('old', -> { 'foo' }, {
            deprecation_info: Twig::DeprecatedCallableInfo.new('foo/bar', '1.1', 'new'),
          }),
        ]
      end

      def filters
        [
          Twig::TwigFilter.new('old_filter', ->(value) { value }, {
            deprecation_info: Twig::DeprecatedCallableInfo.new('foo/bar', '1.1', 'new_filter', 'acme/new', '2.0'),
          }),
        ]
      end

      def tests
        [
          Twig::TwigTest.new('old_test', ->(_value) { true }, {
            deprecation_info: Twig::DeprecatedCallableInfo.new('', ''),
          }),
        ]
      end
    end
  end

  def environment(template)
    Twig::Environment.new(Twig::Loader::Hash.new({ 'index.twig' => template })).tap do |env|
      env.add_extension(extension.new)
    end
  end

  it 'reports a deprecated function where a template uses it' do
    expect { environment("\n{{ old() }}").load('index.twig') }.to output(
      'Deprecation Notice: Since foo/bar 1.1: Twig Function "old" is deprecated; use "new" instead ' \
      "in index.twig at line 2.\n"
    ).to_stdout
  end

  it 'reports a deprecated filter with its replacement package and version' do
    expect { environment('{{ 1|old_filter }}').load('index.twig') }.to output(
      'Deprecation Notice: Since foo/bar 1.1: Twig Filter "old_filter" is deprecated; use "new_filter" ' \
      "from the \"acme/new\" package (available since version 2.0) instead in index.twig at line 1.\n"
    ).to_stdout
  end

  it 'reports a deprecated test without a package or version' do
    expect { environment('{{ 1 is old_test }}').load('index.twig') }.to output(
      "Deprecation Notice: Twig Test \"old_test\" is deprecated in index.twig at line 1.\n"
    ).to_stdout
  end

  it 'only reports a deprecation when the template compiles' do
    env = environment('{{ old() }}')
    expect { env.load('index.twig') }.to output.to_stdout
    expect { env.load('index.twig').render }.not_to output.to_stdout
  end

  it 'rejects deprecation info of another class' do
    expect { Twig::TwigFunction.new('old', -> {}, { deprecation_info: 'soon' }) }.
      to raise_error(Twig::Error::Logic, 'The "deprecation_info" option must be an instance of "Twig::DeprecatedCallableInfo".')
  end
end
