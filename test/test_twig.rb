require 'minitest/autorun'
require 'twig'

module Twig
  class TwigTest < Minitest::Test
    def test_name_variable_lexing
      loader = Loader::ArrayLoader.new(hello: 'Hello {{ name }}! I am {{ other }}')
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
        [Token::NAME_TYPE, 'other'],
        [Token::VAR_END_TYPE, ''],
        [Token::EOF_TYPE, ''],
      ]
    end

    def test_node_must_accept_nodes
      assert_raises do
        Node::Node.new([Hash.new])
      end

      Node::Node.new([Node::Node.new])
    end
    
    def test_parse
      loader = Loader::ArrayLoader.new(hello: 'Hello {{ name }}! I am {{ other }}')
      environment = Environment.new(loader)
      lexer = Lexer.new(environment)
      tokens = lexer.tokenize(loader.get_source_context('hello'))
      parser = Parser.new(environment)

      puts parser.parse(tokens).inspect
    end
  end
end
