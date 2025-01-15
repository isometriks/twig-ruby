# frozen_string_literal: true

module Twig
  # @!attribute [r] environment
  #   @return [Environment]
  class Compiler
    attr_reader :source, :environment

    # @param [Environment] environment
    def initialize(environment)
      @environment = environment
    end

    # @param [Node::Base] node
    # @param [Integer] indentation
    # @return [Compiler]
    def compile(node, indentation = 0)
      reset(indentation)
      node.compile(self)

      self
    end

    # @param [Node::Base] node
    # @param [Boolean] raw
    # @return [Compiler]
    def subcompile(node, raw = true)
      indent_source unless raw

      node.compile(self)

      self
    end

    # @param [Array<String>] strings
    # @return [Compiler]
    def write(*strings)
      strings.each do |string|
        indent_source
        @source << string
      end

      self
    end

    # @param [String] value
    # @return [Compiler]
    def string(value)
      @source << "%q[#{value}]"

      self
    end

    # @param [String] string
    # @return [Compiler]
    def raw(string)
      @source << string

      self
    end

    def repr(value)
      case value
      when Integer, Float
        raw(value.to_s)
      when TrueClass, FalseClass
        raw(value ? 'true' : 'false')
      when NilClass
        raw('nil')
      when Array, Hash
        raw('Marshal.load(').
          raw(Marshal.dump(value).inspect).
          raw(')')
      when String
        string(value)
      else
        string(value)
      end
    end

    # @param [Integer] step
    # @return [Compiler]
    def indent(step = 1)
      @indentation += step

      self
    end

    # @param [Integer] step
    # @return [Compiler]
    def outdent(step = 1)
      @indentation -= step

      self
    end

    private

    def indent_source
      @source << ('  ' * @indentation)
    end

    # @return [Compiler]
    def reset(indentation = 0)
      @last_line = nil
      @source = +''
      @debug_info = []
      @source_offset = 0
      # source code starts at 1 (as we then increment it when we encounter new lines)
      @source_line = 1
      @indentation = indentation
      @var_name_salt = 0

      self
    end
  end
end
