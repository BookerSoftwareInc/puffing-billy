# frozen_string_literal: true

require 'billy'

module Billy
  module Browsers
    class Capybara
      DRIVERS = {
        selenium: 'selenium/webdriver',
        apparition: 'capybara/apparition'
      }.freeze

      def self.register_drivers
        DRIVERS.each do |name, driver|
          require driver
          send("register_#{name}_driver")
        rescue LoadError
        end
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
          options.add_argument("--proxy-server=#{Billy.proxy.host}:#{Billy.proxy.port}")

          ::Capybara::Selenium::Driver.new(
            app, browser: :chrome,
                 options: options
          )
        end

        ::Capybara.register_driver :selenium_chrome_headless_billy do |app|
          options = Selenium::WebDriver::Chrome::Options.new(args: %w[headless=new disable-gpu no-sandbox
                                                                      enable-features=NetworkService,NetworkServiceInProcess])
          options.add_argument("--proxy-server=#{Billy.proxy.host}:#{Billy.proxy.port}")

          ::Capybara::Selenium::Driver.new(
            app, browser: :chrome,
                 options: options
          )
        end
      end

      def self.register_apparition_driver
        ::Capybara.register_driver :apparition_billy do |app|
          ::Capybara::Apparition::Driver.new(app, ignore_https_errors: true).tap do |driver|
            driver.set_proxy(Billy.proxy.host, Billy.proxy.port)
          end
        end
      end
    end
  end
end
