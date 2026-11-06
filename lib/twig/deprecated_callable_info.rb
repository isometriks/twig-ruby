# frozen_string_literal: true

module Twig
  # Marks a function, filter or test as deprecated, as the deprecation_info
  # option of TwigFunction, TwigFilter and TwigTest:
  #
  #   TwigFunction.new('old', method(:old), {
  #     deprecation_info: DeprecatedCallableInfo.new('acme/app', '1.1', 'new'),
  #   })
  #
  # A template using it reports 'Since acme/app 1.1: Twig Function "old" is
  # deprecated; use "new" instead in index.twig at line 2.' when it compiles.
  class DeprecatedCallableInfo
    attr_writer :type, :name

    # @param [String] package
    # @param [String] version
    # @param [String, nil] alt_name
    # @param [String, nil] alt_package
    # @param [String, nil] alt_version
    def initialize(package, version, alt_name = nil, alt_package = nil, alt_version = nil)
      @package = package
      @version = version
      @alt_name = alt_name
      @alt_package = alt_package
      @alt_version = alt_version
    end

    # @param [String, nil] file
    # @param [Integer, nil] line
    def trigger_deprecation(file = nil, line = nil)
      message = "Twig #{@type.to_s.capitalize} \"#{@name}\" is deprecated"

      if @alt_name
        message += "; use \"#{@alt_name}\""
        message += " from the \"#{@alt_package}\" package" if @alt_package
        message += " (available since version #{@alt_version})" if @alt_version
        message += ' instead'
      end

      if file && !file.empty?
        message += " in #{file}"
        message += " at line #{line}" if line
      end

      Extension::Core.trigger_deprecation(@package, @version, "#{message}.")
    end
  end
end
