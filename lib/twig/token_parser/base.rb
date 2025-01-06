module Twig
  module TokenParser
    class Base
      # @return [Parser]
      attr_accessor :parser

      # @param [Token] token
      def parse(token)
        raise "parse is not implemented"
      end

      # @return [String]
      def tag
        raise "tag is not implemented"
      end
    end
  end
end
