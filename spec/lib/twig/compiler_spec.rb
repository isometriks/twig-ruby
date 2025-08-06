# frozen_string_literal: true

require 'spec_helper'

describe Twig::Compiler do
  let(:environment) { instance_double('Twig::Environment') }
  let(:compiler) { described_class.new(environment) }
  let(:node) { instance_double('Twig::Node::Base', lineno: 42) }

  before do
    allow(node).to receive(:compile)
  end

  describe '#initialize' do
    it 'sets the environment' do
      expect(compiler.environment).to eq(environment)
    end
  end

  describe '#compile' do
    it 'resets the compiler and compiles the node' do
      expect(node).to receive(:compile).with(compiler)
      result = compiler.compile(node)
      expect(result).to eq(compiler)
    end

    it 'accepts an optional indentation parameter' do
      indentation = 2
      expect(node).to receive(:compile).with(compiler)
      result = compiler.compile(node, indentation)
      expect(result).to eq(compiler)
    end
  end

  describe '#subcompile' do
    before do
      compiler.instance_variable_set(:@source, +'')
      compiler.instance_variable_set(:@indentation, 1)
    end

    it 'compiles the node without indenting the source by default' do
      expect(node).to receive(:compile).with(compiler)
      result = compiler.subcompile(node)
      expect(result).to eq(compiler)
    end

    it 'indents the source when raw is false' do
      expect(node).to receive(:compile).with(compiler)
      result = compiler.subcompile(node, raw: false)
      expect(result).to eq(compiler)
    end
  end

  describe '#write' do
    it 'appends strings to the source with indentation' do
      compiler.instance_variable_set(:@source, +'')
      compiler.instance_variable_set(:@indentation, 1)

      result = compiler.write('line1', 'line2')

      expect(compiler.instance_variable_get(:@source)).to eq('  line1  line2')
      expect(result).to eq(compiler)
    end
  end

  describe '#string' do
    it 'appends a quoted string to the source' do
      compiler.instance_variable_set(:@source, +'')

      result = compiler.string('test')

      expect(compiler.instance_variable_get(:@source)).to eq('%q[test]')
      expect(result).to eq(compiler)
    end

    it 'escapes brackets and backslashes in the string' do
      compiler.instance_variable_set(:@source, +'')

      result = compiler.string('test[with]\\chars')

      expect(compiler.instance_variable_get(:@source)).to eq('%q[test\[with\]\\\\chars]')
      expect(result).to eq(compiler)
    end
  end

  describe '#symbol' do
    it 'appends a symbol to the source when given a symbol' do
      compiler.instance_variable_set(:@source, +'')

      result = compiler.symbol(:test)

      expect(compiler.instance_variable_get(:@source)).to eq(':test')
      expect(result).to eq(compiler)
    end

    it 'converts a string to a symbol expression when given a string' do
      compiler.instance_variable_set(:@source, +'')

      result = compiler.symbol('test')

      expect(compiler.instance_variable_get(:@source)).to eq('%q[test].to_sym')
      expect(result).to eq(compiler)
    end
  end

  describe '#raw' do
    it 'appends a raw string to the source' do
      compiler.instance_variable_set(:@source, +'')

      result = compiler.raw('raw_content')

      expect(compiler.instance_variable_get(:@source)).to eq('raw_content')
      expect(result).to eq(compiler)
    end
  end

  describe '#repr' do
    it 'handles integers' do
      compiler.instance_variable_set(:@source, +'')

      result = compiler.repr(42)

      expect(compiler.instance_variable_get(:@source)).to eq('42')
      expect(result).to eq(compiler)
    end

    it 'handles floats' do
      compiler.instance_variable_set(:@source, +'')

      result = compiler.repr(3.14)

      expect(compiler.instance_variable_get(:@source)).to eq('3.14')
      expect(result).to eq(compiler)
    end

    it 'handles booleans' do
      compiler.instance_variable_set(:@source, +'')

      compiler.repr(true)
      expect(compiler.instance_variable_get(:@source)).to eq('true')

      compiler.instance_variable_set(:@source, +'')
      compiler.repr(false)
      expect(compiler.instance_variable_get(:@source)).to eq('false')
    end

    it 'handles nil' do
      compiler.instance_variable_set(:@source, +'')

      result = compiler.repr(nil)

      expect(compiler.instance_variable_get(:@source)).to eq('nil')
      expect(result).to eq(compiler)
    end

    it 'handles arrays and hashes using Marshal' do
      compiler.instance_variable_set(:@source, +'')
      array = [1, 2, 3]
      hash = { a: 1, b: 2 }

      compiler.repr(array)
      array_result = compiler.instance_variable_get(:@source)
      expect(array_result).to start_with('Marshal.load(')
      expect(array_result).to end_with(')')

      compiler.instance_variable_set(:@source, +'')
      compiler.repr(hash)
      hash_result = compiler.instance_variable_get(:@source)
      expect(hash_result).to start_with('Marshal.load(')
      expect(hash_result).to end_with(')')
    end

    it 'handles symbols' do
      compiler.instance_variable_set(:@source, +'')

      result = compiler.repr(:symbol)

      expect(compiler.instance_variable_get(:@source)).to eq(':symbol')
      expect(result).to eq(compiler)
    end

    it 'handles other objects as strings' do
      compiler.instance_variable_set(:@source, +'')
      object = Object.new

      result = compiler.repr(object)

      expect(compiler.instance_variable_get(:@source)).to include('%q[')
      expect(result).to eq(compiler)
    end
  end

  describe '#add_debug_info' do
    before do
      compiler.instance_variable_set(:@source, +'')
      compiler.instance_variable_set(:@debug_info, {})
      compiler.instance_variable_set(:@source_offset, 0)
      compiler.instance_variable_set(:@source_line, 1)
      compiler.instance_variable_set(:@last_line, nil)
      compiler.instance_variable_set(:@indentation, 0)
    end

    it 'adds debug info when the line number changes' do
      result = compiler.add_debug_info(node)

      expect(compiler.instance_variable_get(:@source)).to include('# line 42')
      # The debug_info key is 2 because the write method adds a newline which increments the source_line
      expect(compiler.instance_variable_get(:@debug_info)).to include(2 => 42)
      expect(compiler.instance_variable_get(:@last_line)).to eq(42)
      expect(result).to eq(compiler)
    end

    it 'does not add debug info when the line number is the same' do
      compiler.instance_variable_set(:@last_line, 42)

      result = compiler.add_debug_info(node)

      expect(compiler.instance_variable_get(:@source)).to eq('')
      expect(compiler.instance_variable_get(:@debug_info)).to be_empty
      expect(result).to eq(compiler)
    end
  end

  describe '#indent' do
    it 'increases the indentation level' do
      compiler.instance_variable_set(:@indentation, 0)

      result = compiler.indent

      expect(compiler.instance_variable_get(:@indentation)).to eq(1)
      expect(result).to eq(compiler)
    end

    it 'accepts a custom step value' do
      compiler.instance_variable_set(:@indentation, 0)

      result = compiler.indent(3)

      expect(compiler.instance_variable_get(:@indentation)).to eq(3)
      expect(result).to eq(compiler)
    end
  end

  describe '#outdent' do
    it 'decreases the indentation level' do
      compiler.instance_variable_set(:@indentation, 2)

      result = compiler.outdent

      expect(compiler.instance_variable_get(:@indentation)).to eq(1)
      expect(result).to eq(compiler)
    end

    it 'accepts a custom step value' do
      compiler.instance_variable_set(:@indentation, 3)

      result = compiler.outdent(3)

      expect(compiler.instance_variable_get(:@indentation)).to eq(0)
      expect(result).to eq(compiler)
    end
  end

  describe '#var_name' do
    it 'generates unique variable names' do
      compiler.instance_variable_set(:@var_name_salt, 0)

      var1 = compiler.var_name
      var2 = compiler.var_name

      expect(var1).to eq('_v1')
      expect(var2).to eq('_v2')
      expect(var1).not_to eq(var2)
    end
  end
end
