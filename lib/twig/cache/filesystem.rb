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
        Kernel.load(key)

        true
      rescue LoadError
        # Also covers an entry removed between a freshness check and this load
        false
      end

      def write(key, content, mtime: nil)
        dirname = File.dirname(key)

        FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

        # Written through a temporary file and renamed into place, so another
        # thread or process loading the entry never sees it half written.
        tmp = "#{key}.#{SecureRandom.hex(8)}.tmp"
        begin
          File.write(tmp, content)
          File.utime(mtime, mtime, tmp) if mtime
          File.rename(tmp, key)
        ensure
          FileUtils.rm_f(tmp)
        end
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
