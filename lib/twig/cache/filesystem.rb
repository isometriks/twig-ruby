# frozen_string_literal: true

module Twig
  module Cache
    class Filesystem < Cache::Base
      def initialize(directory)
        super()

        @directory = directory
      end

      def generate_key(_name, class_name)
        hash = ::Digest::SHA256.hexdigest(class_name)

        File.join(directory, hash[0] + hash[1], "#{hash}.rb")
      end

      def load(key)
        if File.file?(key)
          Kernel.load(key)

          true
        else
          false
        end
      end

      def write(key, content)
        dirname = File.dirname(key)

        FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
        File.write(key, content)
      end

      def timestamp(key)
        return 0 unless File.file?(key)

        File.mtime(key).to_i
      end

      private

      # @return [String]
      attr_reader :directory
    end
  end
end
