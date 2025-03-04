# frozen_string_literal: true

module Twig
  module TokenParser
    # Prevents compilation of block if function/filter/test does not exist.
    # Since this is at compilation time, this DOES NOT work with Rails helper functions
    # as those can't be determined fully at compile time as of now.
    class Guard < Base
      def parse(token)
        stream = parser.stream
        type_token = stream.expect(Token::NAME_TYPE)

        unless %w[function filter test].include?(type_token.value)
          raise Error::Syntax.new(
            "Supported guard types are function, filter, and test, \"#{token.value}\" given.",
            type_token.lineno,
            stream.source
          )
        end

        name_token = stream.expect(Token::NAME_TYPE)

        begin
          exists = !parser.environment.send(type_token.value, name_token.value).nil?
        rescue Error::Syntax
          exists = false
        end

        stream.expect(Token::BLOCK_END_TYPE)

        if exists
          body = parser.subparse(decide_guard_fork)
        else
          body = Node::Empty.new
          parser.subparse_ignore_unknown_twig_callables(decide_guard_fork)
        end

        else_node = Node::Empty.new

        if stream.next.value == 'else'
          stream.expect(Token::BLOCK_END_TYPE)
          else_node = parser.subparse(decide_guard_end, drop_needle: true)
        end

        stream.expect(Token::BLOCK_END_TYPE)

        Node::Nodes.new(AutoHash.new.add(exists ? body : else_node))
      end

      def tag
        'guard'
      end

      private

      def decide_guard_fork
        ->(token) { token.test(%w[else endguard]) }
      end

      def decide_guard_end
        ->(token) { token.test(['endguard']) }
      end
    end
  end
end
