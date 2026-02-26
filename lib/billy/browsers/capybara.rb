# frozen_string_literal: true

require 'billy'

module Billy
  module Browsers
    class Capybara
      def self.register_drivers
        require 'selenium/webdriver'
        register_selenium_driver
      rescue LoadError
      end

      def self.register_selenium_driver
        ::Capybara.register_driver :selenium_billy do |app|
          options = Selenium::WebDriver::Firefox::Options.new
          options.proxy = Selenium::WebDriver::Proxy.new(
            http: "#{Billy.proxy.host}:#{Billy.proxy.port}",
            ssl: "#{Billy.proxy.host}:#{Billy.proxy.port}"
          )
          ::Capybara::Selenium::Driver.new(app, browser: :firefox, options: options)
        end

        ::Capybara.register_driver :selenium_chrome_billy do |app|
          options = Selenium::WebDriver::Chrome::Options.new
          options.binary = ENV['CHROME_BIN'] if ENV['CHROME_BIN']
          options.add_argument("--proxy-server=#{Billy.proxy.host}:#{Billy.proxy.port}")

          ::Capybara::Selenium::Driver.new(
            app, browser: :chrome,
                 options: options
          )
        end

        ::Capybara.register_driver :selenium_chrome_headless_billy do |app|
          options = Selenium::WebDriver::Chrome::Options.new
          options.binary = ENV['CHROME_BIN'] if ENV['CHROME_BIN']

          options.add_argument("--headless=new")
          options.add_argument("--no-sandbox")
          options.add_argument("--disable-dev-shm-usage")
          options.add_argument("--disable-gpu")

          options.add_argument("--proxy-server=#{Billy.proxy.host}:#{Billy.proxy.port}")

          ::Capybara::Selenium::Driver.new(
            app, browser: :chrome,
                 options: options
          )
        end
      end

    end
  end
end
