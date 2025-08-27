# frozen_string_literal: true

desc 'Tests against Twig PHP fixtures.'

GIT_LOCATION = "#{__dir__}/../../tmp/twig-php".freeze
WONT_IMPLEMENT = %w[
  tags/macro/super_globals.test
  tags/for/non_countable.test
  tags/for/generator.test
  tags/for/objects.test
  tags/for/iterator_aggregate.test
  tags/for/objects_countable.test
  expressions/matches_error_compilation.test
  expressions/matches_error_runtime.test
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
  functions/constant.test
  functions/dump.test
  functions/dump_array.test
  tests/defined_for_attribute.legacy.test
  filters/date_default_format_interval.test
  filters/date_interval.test
  filters/date_immutable.test
  filters/date_modify.test
  operators/not_precedence.test
  operators/concat_vs_add_sub.test
  functions/include/sandbox_disabling.test
  functions/include/sandbox.test
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

task :twig_parity, [:file] do |_t, args|
  require 'rspec/support'
  require_relative '../twig_ruby'
  require_relative '../../test/parity'

  `git clone -b 4.x https://github.com/twigphp/Twig.git #{GIT_LOCATION}`

  stats = { pass: 0, fail: 0, total: 0 }

  fixtures = if args[:file]
               [File.join(GIT_LOCATION, 'tests/Fixtures/', args[:file])]
             else
               Dir.glob("#{GIT_LOCATION}/tests/Fixtures/**/*.test")
             end

  fixtures.each do |fixture|
    base_name = fixture.delete_prefix("#{GIT_LOCATION}/tests/Fixtures/")

    next if WONT_IMPLEMENT.include?(base_name)

    TwigFixture.new(fixture, base_name).call.each do |data|
      stats[:total] += 1

      if data[:status]
        stats[:pass] += 1
      else
        stats[:fail] += 1
        puts '============================='
        puts "FAIL: #{data[:file].delete_prefix("#{GIT_LOCATION}/tests/Fixtures/")}"
        puts data[:error]
        puts "Link: #{data[:file]}:#{data[:lineno]}"
        puts "Rerun: rake twig_parity[#{base_name}]"
        puts "=============================\n\n"
      end
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

  OUTPUTS_REGEX = /
    --DATA--(.*?)(?:--CONFIG--(.*?))?--EXPECT--(.*?)(?=--DATA--|\z)
  /mx

  def initialize(file, base_name)
    @file = file
    @base_name = base_name
  end

  def call
    parse

    require_relative "#{__dir__}/../../test/fixtures/#{@base_name}.rb"
    examples = Data.examples

    examples.each.with_index.map do |example, i|
      build_and_run(example[:data], example[:config], example[:gsub] || {}, outputs[i][2], i)
    end
  end

  private

  attr_accessor :message, :condition, :deprecation, :templates, :exception, :outputs

  def build_and_run(data, config, replacements, expected, index)
    gsub_templates = templates.transform_values do |template|
      replace(template, replacements[:fixture]) + (' ' * index)
    end

    loader = ::Twig::Loader::Hash.new(gsub_templates)
    environment = ::Twig::Environment.new(loader, {
      cache: false,
      strict_variables: true,
      auto_reload: true,
      **config,
    })
    environment.add_global('global', 'global')
    environment.add_extension(::TwigTestExtension.new)
    environment.add_extension(::Twig::Extension::Debug.new)
    environment.add_extension(::Twig::Extension::StringLoader.new)
    environment.add_runtime_loader(::Twig::Parity::Runtime::Loader.new(environment))
    expected ||= ''

    # Reset timezone
    ::Time.zone = 'UTC'

    # Pass current environment if test is lazy
    data = data.call(environment) if data.is_a?(Proc)

    begin
      output = environment.load('index.twig').render(data).gsub(/\A[\n ]*/, '').gsub(/[\n ]*\z/, '')
      output = replace(output, replacements[:output])
      expected = expected.gsub(/\A[\n ]*/, '').gsub(/[\n ]*\z/, '')
      expected = replace(expected, replacements[:result])

      if output == expected
        {
          message:,
          file: @file,
          status: true,
          output:,
        }
      else
        {
          message:,
          file: @file,
          status: false,
          error: ::RSpec::Support::Differ.new.diff_as_string(output, expected),
        }
      end
    rescue ::Twig::Error::Base => e
      if exception
        message_only = exception.match(/Twig\\Error\\\w+: (.*)/)&.captures&.[](0)
        message_only = replace(message_only, replacements[:exception]) if message_only
        exception_matches = message_only == e.message
        error = ::RSpec::Support::Differ.new.diff_as_string(e.message, message_only)
        # error = "#{Color.red("- #{message_only}")}\n#{Color.green("+ #{e.message}")}"
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
    rescue Exception => e # rubocop:disable Lint/RescueException
      {
        message:,
        file: @file,
        status: exception_matches,
        lineno: -1,
        error: "Full Error: #{e.message}",
      }
    end
  end

  def replace(string, replacements)
    return string if replacements.nil?

    replacements.each do |find, replace|
      string = string.gsub(find, replace)
    end

    string
  end

  def contents
    @contents ||= File.read(@file)
  end

  def parse
    if (matches = contents.match(EXCEPTION_REGEX))
      self.message = matches.captures[0]
      self.condition = matches.captures[1]
      self.deprecation = matches.captures[2]
      self.templates = parse_templates(matches.captures[3])
      self.exception = matches.captures[5]
      self.outputs = [[nil, matches.captures[4], nil, '']]
    elsif (matches = contents.match(EXPECT_REGEX))
      self.message = matches.captures[0]
      self.condition = matches.captures[1]
      self.deprecation = matches.captures[2]
      self.templates = parse_templates(matches.captures[3])
      self.exception = false
      self.outputs = contents.scan(OUTPUTS_REGEX)
    end
  end

  def parse_templates(test)
    templates = {}
    test.scan(/--TEMPLATE(?:\((.*?)\))?--(.*?)(?=--TEMPLATE|\z)/mx).map do |name, contents|
      templates[name || 'index.twig'] = contents.
        gsub(/\n*\z/, '').
        gsub('d/m/Y H:i:s P', '%d/%m/%Y %H:%M:%S %:z'). # Change dates to Ruby format
        gsub('Twig\Tests\TwigTestFoo', 'TwigTestFoo') # Change class name to match Ruby
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
