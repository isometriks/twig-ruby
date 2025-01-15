# frozen_string_literal: true

module Twig
  class Source
    attr_reader :code, :name, :path

    def initialize(code, name, path = '')
      @code = code
      @name = name
      @path = path
    end
  end
end
