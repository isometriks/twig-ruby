# frozen_string_literal: true

require_relative 'patches'

class TwigTestExtension < Twig::Extension::Base
  def token_parsers
    [
      TwigTestTokenParser§.new, # rubocop:disable Naming/AsciiIdentifiers
    ]
  end

  def filters
    [
      ::Twig::TwigFilter.new('§', method(:non_ascii_function)),
      ::Twig::TwigFilter.new('nl2br', method('nl2br'), pre_escape: :html, is_safe: [:html]),
      ::Twig::TwigFilter.new('escape_and_nl2br', method(:escape_and_nl2br), {
        needs_environment: true, is_safe: [:html]
      }),
      ::Twig::TwigFilter.new('not', static(:not_filter)),
      ::Twig::TwigFilter.new('escape_something', method(:escape_something), is_safe: [:something]),
      ::Twig::TwigFilter.new('preserves_safety', method(:preserves_safety), preserves_safety: [:html]),
      ::Twig::TwigFilter.new('static_call_string', static(:static_call)),
      ::Twig::TwigFilter.new('static_call_array', static(:static_call)),
      ::Twig::TwigFilter.new('magic_call', [self, :magic_call]),
      ::Twig::TwigFilter.new('magic_call_string', static(:magic_static_call)),
      ::Twig::TwigFilter.new('magic_call_array', static(:magic_static_call)),
      ::Twig::TwigFilter.new(
        'magic_call_closure',
        ->(environment, arg) { environment.extension(TwigTestExtension).magic_call(arg) },
        needs_environment: true
      ),
      ::Twig::TwigFilter.new('*_path', method(:dynamic_path)),
      ::Twig::TwigFilter.new('*_foo_*_bar', method(:dynamic_foo)),
      ::Twig::TwigFilter.new('anon_foo', ->(name) { "*#{name}*" }),
    ]
  end

  def functions
    [
      ::Twig::TwigFunction.new('§', method(:non_ascii_function)),
      ::Twig::TwigFunction.new('safe_br', method(:br), is_safe: [:html]),
      ::Twig::TwigFunction.new('unsafe_br', method(:br)),
      ::Twig::TwigFunction.new('static_call_string', static(:static_call)),
      ::Twig::TwigFunction.new('static_call_array', static(:static_call)),
      ::Twig::TwigFunction.new('*_path', method(:dynamic_path)),
      ::Twig::TwigFunction.new('*_foo_*_bar', method(:dynamic_foo)),
      ::Twig::TwigFunction.new('anon_foo', ->(name) { "*#{name}*" }),
      ::Twig::TwigFunction.new('deprecated_function', -> { 'foo' }), # @todo - Needs deprecation info
    ]
  end

  def tests
    [
      ::Twig::TwigTest.new('multi word', static(:multi_word?)),
      ::Twig::TwigTest.new('test_*', method(:dynamic_test)),
    ]
  end

  def non_ascii_function(value)
    "§#{value}§"
  end

  def br
    '<br />'
  end

  # @param [Twig::Environment] env
  def escape_and_nl2br(env, value, sep = '<br />')
    nl2br(
      env.runtime(Twig::Runtime::Escaper).escape(value, :html),
      sep
    )
  end

  def nl2br(value, sep = '<br />')
    value&.gsub("\n", "#{sep}\n")
  end

  def dynamic_path(element, item)
    "#{element}/#{item}"
  end

  def dynamic_foo(foo, bar, item)
    "#{foo}/#{bar}/#{item}"
  end

  def dynamic_test(element, item)
    element == item
  end

  # @param [String] value
  def escape_something(value)
    value.upcase
  end

  # @param [String] value
  def preserves_safety(value)
    value.upcase
  end

  def magic_call(arg)
    "magic_#{arg}"
  end

  def self.static_call(value)
    "*#{value}*"
  end

  def self.not_filter(value)
    "not #{value}"
  end

  def self.method_missing(method, *args)
    unless method == :magic_static_call
      raise "Method #{method} does not exist"
    end

    "static_magic_#{args.first}"
  end

  def self.respond_to_missing?(method, include_private = false)
    [:magic_static_call].include?(method.to_sym)
  end

  def respond_to_missing?(method, include_private = false)
    [:magic_call].include?(method.to_sym)
  end

  def self.multi_word?(string)
    string.include?(' ')
  end
end

class TwigTestTokenParser§ < Twig::TokenParser::Base # rubocop:disable Naming/AsciiIdentifiers
  def parse(token)
    parser.stream.expect(Twig::Token::BLOCK_END_TYPE)

    Twig::Node::Print.new(Twig::Node::Expression::Constant.new('§', -1), -1)
  end

  def tag
    '§'
  end
end

class Fixture
  class << self
    attr_accessor :twig
  end
end

class TwigConstants
  ARRAY_AS_PROPS = true
end

class TwigCountableStub
  def initialize(value)
    @value = value
  end

  def length
    @value
  end
end

class TwigToStringStub
  def initialize(value)
    @value = value
  end

  def to_s
    @value
  end
end

class TwigMagicCallStub
  def method_missing(...)
    1
  end

  def respond_to_missing?(method, include_private = false)
    true
  end
end

class TwigSimpleIteratorForTesting
  include Enumerable

  def initialize
    @items = [1, 2, 3, 4, 5, 6, 7]
  end

  def each(&)
    @items.each(&)
  end
end

class TwigTestObj; end # rubocop:disable Lint/EmptyClass

class TwigTestFoo
  BAR_NAME = 'bar'
  ARRAY_AS_PROPS = 2

  def to_a
    [1, 2]
  end

  def empty
    ''
  end

  def foo
    'foo'
  end

  def bar(a = nil, b = nil, param1: nil, param2: nil)
    a ||= param1
    b ||= param2
    "bar#{"_#{a}" if a}#{"-#{b}" if b}"
  end

  # Just for passing tests, no need to implement getX stuff for ruby
  def getFoo(var = nil) # rubocop:disable Naming/MethodName
    'foo'
  end

  def null
    nil
  end

  def self
    self
  end

  def is
    'is'
  end

  def in
    'in'
  end

  def not
    'not'
  end
end
