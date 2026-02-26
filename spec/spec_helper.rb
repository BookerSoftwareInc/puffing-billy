# frozen_string_literal: true

Dir[File.expand_path('support/**/*.rb', __dir__)].each { |f| require f }

require 'pry'
require 'billy/capybara/rspec'
require 'billy/watir/rspec'
require 'rack'
require 'logger'
require 'fileutils'

# Patch RequestLog#complete to accept optional cache_key (lib bug: line 31 of request_handler.rb passes only 2 args)
module Billy
  class RequestLog
    def complete(request, handler, cache_key = nil)
      return unless Billy.config.record_requests

      request.merge! status: :complete,
                     handler: handler,
                     cache_key: cache_key
    end
  end
end

browser = Billy::Browsers::Watir.new :chrome
Capybara.app = Rack::Directory.new(File.expand_path('../examples', __dir__))
Capybara.server = :puma, { Silent: true }
Capybara.javascript_driver = :selenium_chrome_headless_billy

Billy.configure do |config|
  config.logger = Logger.new(File.expand_path('../log/test.log', __dir__))
end

RSpec.configure do |config|
  include Billy::TestServer
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'

  config.before :suite do
    FileUtils.rm_rf(Billy.config.certs_path)
    FileUtils.rm_rf(Billy.config.cache_path)
  end

  config.before :all do
    start_test_servers
    @browser = browser
  end

  config.before do
    proxy.reset_cache
  end

  config.after do
    Billy.config.reset
  end

  config.after :suite do
    browser.close
  end
end
