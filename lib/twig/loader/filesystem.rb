# frozen_string_literal: true

module Twig
  module Loader
    class Filesystem < Loader::Base
      def initialize(root_path, paths = [])
        super()

        @root_path = root_path.to_s
        @paths = paths.map(&:to_s)
      end

      def get_source_context(name)
        if (file = find_template(name))
          return Source.new(File.read(file), name, file)
        end

        raise "Unable to find '#{name}'"
      end

      def get_cache_key(name)
        return unless (path = find_template(name))

        path.delete_prefix(@root_path)
      end

      def fresh?(name, time)
        if (file = find_template(name))
          return File.mtime(file).to_i < time
        end

        false
      end

      private

      def find_template(name)
        @paths.each do |path|
          absolute = File.join(@root_path, path, name)
          return absolute if File.file?(absolute)
        end
      end
    end
  end
end
