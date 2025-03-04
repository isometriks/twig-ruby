# frozen_string_literal: true

require_relative '../twig_ruby'

desc 'Tests against Twig PHP fixtures.'

GIT_LOCATION = "#{__dir__}/../../tmp/twig-php".freeze

task :twig_parity do
  `git clone -b 4.x https://github.com/twigphp/Twig.git #{GIT_LOCATION}`

  stats = { pass: 0, fail: 0, total: 0 }

  Dir.glob("#{GIT_LOCATION}/tests/Fixtures/**/*.test").each do |fixture|
    data = TwigFixture.new(fixture).call
    stats[:total] += 1

    if data[:status]
      stats[:pass] += 1
    else
      stats[:fail] += 1
      puts "FAIL: #{data[:file].delete_prefix("#{GIT_LOCATION}/tests/Fixtures/")}"
      puts "  => #{data[:error].message}"
      puts "  Link: #{data[:file]}:#{data[:error].lineno}"
    end
  end

  puts <<~STATS

    Stats:
      #{stats[:pass]} passed,
      #{stats[:fail]} failed,
      correct: #{(stats[:pass] * 100 / stats[:total]).round(2)}%
  STATS

  if (stats[:fail]).positive?
    exit 1
  else
    exit 0
  end
end

class TwigFixture
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

    begin
      environment.load_template('index.twig')

      {
        message:,
        file: @file,
        status: true,
      }
    rescue ::Twig::Error::Base => e
      {
        message:,
        file: @file,
        status: false,
        error: e,
      }
    end
  end

  private

  attr_accessor :message, :condition, :deprecation, :templates, :exception, :outputs

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
  def filters
    [
      ::Twig::TwigFilter.new('not', static(:not_filter)),
    ]
  end

  def self.not_filter(value)
    "not #{value}"
  end
end
