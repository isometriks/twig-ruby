require 'minitest/autorun'
require 'twig'

module Twig
  class TwigTest < Minitest::Test
    def test_name_variable_lexing
      loader = Loader::ArrayLoader.new(hello: 'Hello {{ name }}! I am {{ a + (50 * 2) }}')
      environment = Environment.new(loader)
      lexer = Lexer.new(environment)

      tokens = lexer.
        tokenize(loader.get_source_context('hello')).
        tokens.
        map { |token| [token.type, token.value] }

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
        Node::Node.new({ 0 => Hash.new })
      end

      Node::Nodes.new({ 0 => Node::TextNode.new("test") })
    end
    
    def test_parse
      loader = Loader::ArrayLoader.new(hello: 'Hello {{ name|capitalize }}')
      environment = Environment.new(loader)
      lexer = Lexer.new(environment)
      parser = Parser.new(environment)
      compiler = Compiler.new(environment)

      tokens = lexer.tokenize(loader.get_source_context('hello'))
      nodes = parser.parse(tokens)

      raise "\n\n" + compiler.compile(nodes).source
    end
  end
end
