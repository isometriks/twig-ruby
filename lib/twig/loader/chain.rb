# frozen_string_literal: true

module Twig
  module Loader
    class Chain < Loader::Base
      # @param [Array<Loader::Base>] loaders
      def initialize(loaders)
        super()

        @loaders = loaders
      end

      def get_source_context(name)
        exceptions = []

        loaders.each do |loader|
          unless loader.exists?(name)
            next
          end

          begin
            return loader.get_source_context(name)
          rescue Twig::Error::Loader => e
            exceptions << "#{loader.class.name}: #{e.message}"
          end
        end

        exceptions = exceptions.any? ? "(#{exceptions.join(', ')})" : ''

        raise Twig::Error::Loader, "Template #{name} is not defined#{exceptions}."
      end

      def exists?(name)
        @has_source_cache ||= {}

        return @has_source_cache[name] if @has_source_cache.key?(name)

        loaders.each do |loader|
          if loader.exists?(name)
            return @has_source_cache[name] = true
          end
        end

        @has_source_cache[name] = false
      end

      def get_cache_key(name)
        exceptions = []

        loaders.each do |loader|
          unless loader.exists?(name)
            next
          end

          begin
            return loader.get_cache_key(name)
          rescue Twig::Error::Loader => e
            exceptions << "#{loader.class.name}: #{e.message}"
          end
        end

        exceptions = exceptions.any? ? "(#{exceptions.join(', ')})" : ''

        raise Twig::Error::Loader, "Template #{name} is not defined#{exceptions}."
      end

      def fresh?(name, time)
        exceptions = []

        loaders.each do |loader|
          unless loader.exists?(name)
            next
          end

          begin
            return loader.fresh?(name, time)
          rescue Twig::Error::Loader => e
            exceptions << "#{loader.class.name}: #{e.message}"
          end
        end

        exceptions = exceptions.any? ? "(#{exceptions.join(', ')})" : ''

        raise Twig::Error::Loader, "Template #{name} is not defined#{exceptions}."
      end

      private

      # @return [::Array<Loader::Base>]
      attr_accessor :loaders
    end
  end
end
