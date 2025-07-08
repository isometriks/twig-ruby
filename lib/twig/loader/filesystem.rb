# frozen_string_literal: true

module Twig
  module Loader
    class Filesystem < Loader::Base
      MAIN_NAMESPACE = '__main__'

      def initialize(root_path, paths = [])
        super()

        @root_path = root_path.to_s
        @paths = {}
        @cache = {}
        @error_cache = {}

        set_paths(paths)
      end

      def exists?(name)
        return true if @cache.key?(name)

        !find_template(name, throw: false).nil?
      end

      def paths(namespace = MAIN_NAMESPACE)
        @paths[namespace] || []
      end

      def set_paths(paths, namespace = MAIN_NAMESPACE)
        paths = [paths] unless paths.is_a?(::Array)

        @paths[namespace] = []

        paths.each do |path|
          add_path(path, namespace)
        end
      end

      def add_path(path, namespace = MAIN_NAMESPACE)
        @cache = {}
        @error_cache = {}
        check_path = path[0] == '/' ? path : File.join(@root_path, path)

        unless File.directory?(check_path)
          raise Error::Loader, "The \"#{path}\" directory does not exist (#{check_path})."
        end

        @paths[namespace] ||= []
        @paths[namespace] << path
      end

      def prepend_path(path, namespace = MAIN_NAMESPACE)
        @cache = {}
        @error_cache = {}
        check_path = path[0] == '/' ? path : File.join(@root_path, path)

        unless File.directory?(check_path)
          raise Error::Loader, "The \"#{path}\" directory does not exist (#{check_path})."
        end

        @paths[namespace] ||= []
        @paths[namespace].unshift(path)
      end

      def get_source_context(name)
        if (file = find_template(name))
          return Source.new(File.read(file), name, file)
        end

        raise Error::Loader, "Unable to find template \"#{name}\" (looked into: #{@paths.inspect})."
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

      def find_template(name, throw: true)
        return @cache[name] if @cache.key?(name)

        begin
          namespace, shortname = parse_name(name)
        rescue Error::Loader => e
          return nil unless throw
          raise e if throw
        end

        unless @paths.key?(namespace)
          @error_cache[name] = "There are no registered paths for namespace \"#{namespace}\"."

          unless throw
            return nil
          end

          raise Error::Loader, @error_cache[name]
        end

        paths(namespace).each do |path|
          absolute = File.join(path, shortname)

          unless path[0] == '/'
            absolute = File.join(@root_path, absolute)
          end

          if File.file?(absolute)
            return @cache[name] = absolute
          end
        end

        @error_cache[name] = "Unable to find template \"#{name}\" (looked into: #{@paths.inspect})."

        unless throw
          return nil
        end

        raise Error::Loader, @error_cache[name]
      end

      def parse_name(name)
        if name[0] == '@'
          if (pos = name.index('/')).nil?
            raise Error::Loader, "Malformed namespaced template name \"#{name}\" " \
                                 '(expecting "@namespace/template_name").'
          end

          return [name[1...pos], name[(pos + 1)..]]
        end

        [MAIN_NAMESPACE, name]
      end
    end
  end
end
