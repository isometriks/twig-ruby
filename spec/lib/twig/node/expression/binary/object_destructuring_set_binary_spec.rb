# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Binary::ObjectDestructuringSetBinary do
  describe 'hash destructuring' do
    it_behaves_like 'render_and_assert' do
      let(:input) { '{% do {first_name, last_name} = user %}{{ first_name }} {{ last_name }}' }
      let(:output) { 'Fabien Potencier' }
      let(:locals) { { user: { first_name: 'Fabien', last_name: 'Potencier' } } }
    end
  end

  describe 'hash destructuring with string keys' do
    it_behaves_like 'render_and_assert' do
      let(:input) { '{% do {name, email} = user %}{{ name }} {{ email }}' }
      let(:output) { 'Fabien fabien@example.com' }
      let(:locals) { { user: { 'name' => 'Fabien', 'email' => 'fabien@example.com' } } }
    end
  end

  describe 'object destructuring via method access' do
    it_behaves_like 'render_and_assert' do
      let(:input) { '{% do {name} = user %}{{ name }}' }
      let(:output) { 'Fabien' }
      let(:locals) do
        user = Object.new
        user.define_singleton_method(:name) { 'Fabien' }
        { user: }
      end
    end
  end

  describe 'renaming variables during destructuring' do
    it_behaves_like 'render_and_assert' do
      let(:input) { '{% do {name: user_name, email: user_email} = user %}{{ user_name }} {{ user_email }}' }
      let(:output) { 'Fabien fabien@example.com' }
      let(:locals) { { user: { 'name' => 'Fabien', 'email' => 'fabien@example.com' } } }
    end
  end

  describe 'renaming with method access' do
    it_behaves_like 'render_and_assert' do
      let(:input) { '{% do {name: obj_name} = user %}{{ obj_name }}' }
      let(:output) { 'Fabien' }
      let(:locals) do
        user = Object.new
        user.define_singleton_method(:name) { 'Fabien' }
        { user: }
      end
    end
  end

  describe 'multiple destructuring statements' do
    it_behaves_like 'render_and_assert' do
      let(:input) { '{% do {name: n1} = a %}{% do {name: n2} = b %}{{ n1 }} {{ n2 }}' }
      let(:output) { 'Alice Bob' }
      let(:locals) { { a: { 'name' => 'Alice' }, b: { 'name' => 'Bob' } } }
    end
  end

  describe 'evaluating the source only once' do
    let(:calls) { [] }
    let(:counting_extension) do
      calls = self.calls

      Class.new(Twig::Extension::Base) do
        define_method(:functions) do
          [
            Twig::TwigFunction.new('next_value', lambda {
              calls << (calls.length + 1)
              { 'first' => calls.length, 'second' => calls.length }
            }),
          ]
        end
      end.new
    end

    it_behaves_like 'render_and_assert' do
      let(:extensions) { [counting_extension] }
      let(:input) do
        '{% do [result_first, result_second] = ({first, second} = next_value()) %}' \
          '{{ first }} {{ second }} {{ result_first }} {{ result_second }}'
      end
      let(:output) { '1 1 1 1' }
    end

    it 'calls the source once' do
      loader = Twig::Loader::Hash.new({ 'template' => '{% do {first, second} = next_value() %}' })
      environment = Twig::Environment.new(loader)
      environment.add_extension(counting_extension)
      environment.load('template').render({})

      expect(calls).to eq([1])
    end
  end

  describe 'evaluating a source with side effects only once' do
    it_behaves_like 'render_and_assert' do
      let(:input) { '{% set c = 0 %}{% do {a, b} = (c = c + 1) ? {a: c, b: 2} : {} %}{{ c }} {{ a }}{{ b }}' }
      let(:output) { '1 12' }
    end
  end

  describe 'returning the extracted values' do
    it_behaves_like 'render_and_assert' do
      let(:input) { '{{ ({name, email} = user)|join(",") }}' }
      let(:output) { 'Fabien,fabien@example.com' }
      let(:locals) { { user: { 'name' => 'Fabien', 'email' => 'fabien@example.com' } } }
    end
  end

  context 'when destructuring to a non-variable' do
    it_behaves_like 'render_and_raise' do
      let(:template) { '{% do {name: "literal"} = user %}' }
      let(:error) { Twig::Error::Syntax }
      let(:message) { %r{only variables can be assigned in object/mapping destructuring} }
    end
  end
end
