# frozen_string_literal: true

require 'minitest/autorun'
require 'twig-ruby'

module Twig
  class TwigTest < Minitest::Test
    def test_name_variable_lexing
      loader = Loader::Array.new(hello: 'Hello {{ name }}! I am {{ a + (50 * 2) }}')
      environment = Environment.new(loader)
      lexer = Lexer.new(environment)

      tokens = lexer.
        tokenize(loader.get_source_context(:hello)).
        tokens.
        map(&:debug)

      assert_equal tokens, [
        [Token::TEXT_TYPE, 'Hello '],
        [Token::VAR_START_TYPE, ''],
        [Token::NAME_TYPE, 'name'],
        [Token::VAR_END_TYPE, ''],
        [Token::TEXT_TYPE, '! I am '],
        [Token::VAR_START_TYPE, ''],
        [Token::NAME_TYPE, 'a'],
        [Token::OPERATOR_TYPE, '+'],
        [Token::PUNCTUATION_TYPE, '('],
        [Token::NUMBER_TYPE, 50.0],
        [Token::OPERATOR_TYPE, '*'],
        [Token::NUMBER_TYPE, 2.0],
        [Token::PUNCTUATION_TYPE, ')'],
        [Token::VAR_END_TYPE, ''],
        [Token::EOF_TYPE, ''],
      ]
    end

    def test_node_must_accept_nodes
      assert_raises do
        Node::Nodes.new({ 0 => Hash.new })
      end

      Node::Nodes.new({ 0 => Node::Text.new('test') })
    end

    def test_filter
      template = 'Hello {{ name|capitalize }}'
      context = { name: 'world' }

      assert_equal('Hello World', compile_and_run(template, context))
    end

    def test_math
      [
        ['{{ 5 + 5 }}', '10'],
        ['{{ 5 + 1 * 2 }}', '7'],
        ['{{ "hey" }}', 'hey'],
        ['{{ "hey"|capitalize }}', 'Hey'],
        ['{{ "hello " ~ \'world\' }}', 'hello world'],
        ['{{ "hello "|capitalize ~ "world" }}', 'Hello world'],
        ['{% verbatim %} what up {% endverbatim %}', ' what up '],
        ["{% verbatim %} what up\n  {%- endverbatim %}", " what up\n"], # Leave line break for -
        ["{% verbatim %} what up\n  {%~ endverbatim %}", ' what up'], # Strip all for ~
        ["before\n{% line 10 %}\nafter", "before\n\nafter"],
        ['{% block test %}hello{% endblock %}', 'hello'],
        ['{{ "<h1>Hello</h1>" }}', '&lt;h1&gt;Hello&lt;/h1&gt;']
      ].
        each do |input, expected, context|
          assert_equal(expected, compile_and_run(input, context || {}))
        end
    end

    def test_file
      loader = Twig::Loader::File.new([__dir__ + '/fixtures/'])
      environment = Twig::Environment.new(loader)

      puts environment.load_and_compile('full.html.twig')

      # Create the class in memory
      template = eval(environment.load_and_compile('child.html.twig'))
      result = template.new(environment).render({ name: 'Craig' })
      puts result
    end

    private

    def compile_and_run(template_contents, context = {})
      template_key = :test
      loader = Loader::Array.new([[template_key, template_contents]].to_h)
      environment = Environment.new(loader)
      lexer = Lexer.new(environment)
      parser = Parser.new(environment)
      compiler = Compiler.new(environment)

      tokens = lexer.tokenize(loader.get_source_context(template_key))
      nodes = parser.parse(tokens)

      # Create the class in memory
      template = eval(compiler.compile(nodes).source)
      template.new(environment).render(context).to_s
    end
  end
end
