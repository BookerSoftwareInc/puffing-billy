# frozen_string_literal: true

require 'billy'
require 'watir'

module Billy
  module Browsers
    class Watir < ::Watir::Browser
      def initialize(name, args = {})
        args = case name
               when :chrome then configure_chrome(args)
               when :firefox then configure_firefox(args)
               else
                 raise NameError, 'Invalid browser driver specified. (Expected: :chrome, :firefox)'
               end
        super
      end

      private

      def configure_chrome(args)
        options = args.delete(:options) || Selenium::WebDriver::Chrome::Options.new
        options.add_argument("--proxy-server=#{Billy.proxy.host}:#{Billy.proxy.port}")
        args[:options] = options
        args
      end

      def configure_firefox(args)
        options = args.delete(:options) || Selenium::WebDriver::Firefox::Options.new
        options.proxy = Selenium::WebDriver::Proxy.new(
          http: "#{Billy.proxy.host}:#{Billy.proxy.port}",
          ssl: "#{Billy.proxy.host}:#{Billy.proxy.port}"
        )
        args[:options] = options
        args
      end
    end
  end
end
