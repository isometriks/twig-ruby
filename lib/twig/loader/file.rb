# frozen_string_literal: true

module Twig
  module Loader
    class File < Loader::Base
      def initialize(paths = [])
        @paths = paths
      end

      def get_source_context(name)
        @paths.each do |path|
          if ::File.file?(path + name)
            return Source.new(::File.read(path + name), name)
          end
        end

        raise "Unable to find '#{name}'"
      end
    end
  end
end
