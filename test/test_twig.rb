require "minitest/autorun"
require "twig"

class TwigTest < Minitest::Test
  def test_lexing
    loader = Twig::Loader::ArrayLoader.new(hello: "Hello {{- name }}! I am {{ other }}")
    #environment = Twig::Environment.new(loader)
    lexer = Twig::Lexer.new

    p lexer.tokenize((loader.get_source_context("hello")))
  end
end
