# frozen_string_literal: true

require_relative '../twig_ruby'

desc 'Tests against Twig PHP fixtures.'

GIT_LOCATION = "#{__dir__}/../../tmp/twig-php".freeze
WONT_IMPLEMENT = %w[
  tags/macro/super_globals.test
  functions/enum/invalid_dynamic_enum.test
  functions/enum/invalid_enum.test
  functions/enum/invalid_literal_type.test
  functions/enum/valid.test
  functions/enum_cases/invalid_dynamic_enum.test
  functions/enum_cases/invalid_enum.test
  functions/enum_cases/invalid_literal_type.test
  functions/enum_cases/valid.test
  functions/attribute.legacy.test
  functions/attribute_with_wrong_args.legacy.test
  tests/defined_for_attribute.legacy.test
].freeze

class Color
  def self.colorize(text, color_code)
    "\e[#{color_code}m#{text}\e[0m"
  end

  def self.red(text)
    colorize(text, 31)
  end

  def self.green(text)
    colorize(text, 32)
  end
end

task :twig_parity do
  `git clone -b 4.x https://github.com/twigphp/Twig.git #{GIT_LOCATION}`

  stats = { pass: 0, fail: 0, total: 0 }

  Dir.glob("#{GIT_LOCATION}/tests/Fixtures/**/*.test").each do |fixture|
    next if WONT_IMPLEMENT.include?(fixture.delete_prefix("#{GIT_LOCATION}/tests/Fixtures/"))

    data = TwigFixture.new(fixture).call
    stats[:total] += 1

    if data[:status]
      stats[:pass] += 1
    else
      stats[:fail] += 1
      puts '============================='
      puts "FAIL: #{data[:file].delete_prefix("#{GIT_LOCATION}/tests/Fixtures/")}"
      puts "--------\n#{data[:error]}\n--------"
      puts "Link: #{data[:file]}:#{data[:lineno]}"
      puts "=============================\n\n"
    end
  end

  puts <<~STATS

    Stats:
      #{Color.green("#{stats[:pass]} passed")}
      #{Color.red("#{stats[:fail]} failed")}
      correct: #{(stats[:pass] * 100 / stats[:total]).round(2)}%
  STATS

  if stats[:fail].positive?
    exit 1
  else
    exit 0
  end
end

class TwigFixture
  EXCEPTION_REGEX = /
    --TEST--\s*(.*?)\s*
    (?:--CONDITION--\s*(.*))?\s*
    (?:--DEPRECATION--\s*(.*?))?\s*
    ((?:--TEMPLATE(?:\(.*?\))?--(?:.*?))+)\s*
    (?:--DATA--\s*(.*))?\s*
    --EXCEPTION--\s*(.*)
  /mx

  EXPECT_REGEX = /
    --TEST--\s*(.*?)\s*
    (?:--CONDITION--\s*(.*))?\s*
    (?:--DEPRECATION--\s*(.*?))?\s*
    ((?:--TEMPLATE(?:\(.*?\))?--(?:.*?))+)
    --DATA--.*?
    --EXPECT--.*
  /mx

  def initialize(file)
    @file = file
  end

  def call
    parse

    loader = ::Twig::Loader::Array.new(templates)
    environment = ::Twig::Environment.new(loader, {
      cache: false,
    })
    environment.add_extension(::TwigTestExtension.new)
    environment.add_extension(::Twig::Extension::Debug.new)
    environment.add_extension(::Twig::Extension::StringLoader.new)

    begin
      environment.load('index.twig')

      {
        message:,
        file: @file,
        status: true,
      }
    rescue ::Twig::Error::Base => e
      if exception
        message_only = exception.match(/Twig\\Error\\\w+: (.*)/).captures[0]
        exception_matches = message_only == e.message
        error = "#{Color.red("- #{message_only}")}\n#{Color.green("+ #{e.message}")}"
      else
        error = Color.red(e.message)
      end

      {
        message:,
        file: @file,
        status: exception_matches,
        lineno: e.lineno,
        error:,
      }
    end
  end

  private

  attr_accessor :message, :condition, :deprecation, :templates, :exception, :outputs

  def contents
    @contents ||= File.read(@file)
  end

  def parse
    if (matches = contents.match(EXCEPTION_REGEX))
      self.message = matches.captures[0]
      self.condition = matches.captures[1]
      self.deprecation = matches.captures[2]
      self.templates = parse_templates(matches.captures[3]) # @todo actually parse the templates
      self.exception = matches.captures[5]
      self.outputs = matches.captures[4] #  $outputs = [[null, $match[5], null, '']];
    elsif (matches = contents.match(EXPECT_REGEX))
      self.message = matches.captures[0]
      self.condition = matches.captures[1]
      self.deprecation = matches.captures[2]
      self.templates = parse_templates(matches.captures[3])
      self.exception = false
      self.outputs = nil
      # preg_match_all('/--DATA--(.*?)(?:--CONFIG--(.*?))?--EXPECT--(.*?)(?=\-\-DATA\-\-|$)/s',
      # $test, $outputs, \PREG_SET_ORDER);
    end
  end

  def parse_templates(test)
    templates = {}
    test.scan(/--TEMPLATE(?:\((.*?)\))?--(.*?)(?=--TEMPLATE|\z)/mx).map do |name, contents|
      templates[name || 'index.twig'] = contents
    end

    templates
  end

  def parse_return_value(object)
    if object.is_a?(Array) && object.length == 1
      return parse_return_value(object.first)
    end

    if object.is_a?(Hash)
      return object.transform_values { |v| parse_return_value(v) }
    end

    object
  end
end

class TwigTestExtension < Twig::Extension::Base
  def token_parsers
    [
      TwigTestTokenParser§.new, # rubocop:disable Naming/AsciiIdentifiers
    ]
  end

  def filters
    [
      ::Twig::TwigFilter.new('nl2br', method('nl2br'), pre_escape: [:html], is_safe: [:html]),
      ::Twig::TwigFilter.new('escape_and_nl2br', method(:escape_and_nl2br), {
        needs_environment: true, is_safe: [:html]
      }),
      ::Twig::TwigFilter.new('not', static(:not_filter)),
      ::Twig::TwigFilter.new('escape_something', method(:escape_something), is_safe: [:something]),
      ::Twig::TwigFilter.new('preserves_safety', method(:preserves_safety), is_safe: [:html]),
      ::Twig::TwigFilter.new('static_call_string', static(:static_call)),
      ::Twig::TwigFilter.new('static_call_array', static(:static_call)),
      ::Twig::TwigFilter.new('magic_call', [self, :magic_call]),
      ::Twig::TwigFilter.new('magic_call_string', static(:magic_static_call)),
      ::Twig::TwigFilter.new('magic_call_array', static(:magic_static_call)),
      ::Twig::TwigFilter.new(
        'magic_call_closure',
        ->(environment:) { environment.extension(TwigTestExtension).magic_call },
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
    value.gsub("\n", "#{sep}\n")
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

  def magic_call
    'foo'
  end

  def self.static_call(value)
    "*#{value}*"
  end

  def self.magic_static_call(value)
    'foo'
  end

  def self.not_filter(value)
    "not #{value}"
  end

  def self.method_missing(method)
    raise method.inspect
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

# Rubo
class TwigTestTokenParser§ < Twig::TokenParser::Base # rubocop:disable Naming/AsciiIdentifiers
  def parse(token)
    parser.stream.expect(Twig::Token::BLOCK_END_TYPE)

    Twig::Node::Print.new(Twig::Node::Expression::Constant.new('§', -1), -1)
  end

  def tag
    '§'
  end
end
