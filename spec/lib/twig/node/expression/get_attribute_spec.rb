# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::Node::Expression::GetAttribute do
  describe 'the line of an attribute error' do
    {
      "{{ foo\n?.bar\n.nope }}" => 2,
      "{{ foo.bar\n.nope }}" => 1,
      "{{ foo\n.bar\n.nope\n.qux }}" => 2,
      "{{ foo\n.nope }}" => 1,
      "{{ foo\n[\n'nope'] }}" => 1,
    }.each do |source, line|
      it "is the line of the object for #{source.inspect}" do
        environment = Twig::Environment.new(
          Twig::Loader::Hash.new({ 'index' => source }),
          { strict_variables: true }
        )

        expect { environment.load('index').render({ foo: { 'bar' => { 'baz' => 1 } } }) }.
          to raise_error(Twig::Error::Runtime, /does not exist in "index" at line #{line}\.\z/)
      end
    end
  end
end
