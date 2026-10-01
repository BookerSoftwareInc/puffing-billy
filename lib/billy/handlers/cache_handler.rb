# frozen_string_literal: true

require 'billy/handlers/handler'
require 'addressable/uri'
require 'cgi'

module Billy
  class CacheHandler
    extend Forwardable
    include Handler

    attr_reader :cache

    def_delegators :cache, :reset, :cached?

    def initialize
      @cache = Billy::Cache.instance
    end

    def handle_request(method, url, headers, body, cache_scope)
      method = method.downcase
      if handles_request?(method, url, headers, body,
                          cache_scope) && (response = cache.fetch(method, url, body, cache_scope))
        Billy.log(:info, "puffing-billy: CACHE #{method} for '#{url}'")

        replace_response_callback(response, url) if Billy.config.dynamic_jsonp

        if Billy.config.after_cache_handles_request
          request = { method: method, url: url, headers: headers, body: body }
          Billy.config.after_cache_handles_request.call(request, response)
        end

        Kernel.sleep(Billy.config.cache_simulates_network_delay_time) if Billy.config.cache_simulates_network_delays

        return response
      end
      nil
    end

    def handles_request?(method, url, _headers, body, cache_scope)
      return false if Billy.config.refresh_persisted_cache

      cached?(method, url, body, cache_scope)
    end

    private

    def replace_response_callback(response, url)
      request_uri = Addressable::URI.parse(url)
      return unless request_uri.query

      params = CGI.parse(request_uri.query)
      callback_name = Billy.config.dynamic_jsonp_callback_name
      return unless params[callback_name].any? && response[:content].match(/\w+\(/)

      response[:content] = response[:content].sub(/\w+\(/, "#{params[callback_name].first}(")
    end
  end
end
