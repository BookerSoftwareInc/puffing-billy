require 'spec_helper'

describe Billy::RequestLog do
  let(:request_log) { Billy::RequestLog.new }
  let(:cache_scope) { 0 }
  let(:cache_key) { 'cache_key' }

  describe '#record' do
    it 'returns the request details if record_requests is enabled' do
      allow(Billy::config).to receive(:record_requests).and_return(true)
      expected_request = {
        scope: cache_scope,
        cache_key: nil,
        status: :inflight,
        handler: nil,
        method: :method,
        url: :url,
        headers: :headers,
        body: :body
      }
      expect(request_log.record(:method, :url, :headers, :body, cache_scope)).to eql(expected_request)
    end

    it 'returns nil if record_requests is disabled' do
      allow(Billy::config).to receive(:record_requests).and_return(false)
      expect(request_log.record(:method, :url, :headers, :body, cache_scope)).to be_nil
    end
  end

  describe '#complete' do
    it 'marks the request as complete if record_requests is enabled' do
      allow(Billy::config).to receive(:record_requests).and_return(true)

      request = request_log.record(:method, :url, :headers, :body, cache_scope)
      expected_request = {
        scope: cache_scope,
        cache_key: cache_key,
        status: :complete,
        handler: :handler,
        method: :method,
        url: :url,
        headers: :headers,
        body: :body
      }
      expect(request_log.complete(request, :handler, cache_key)).to eql(expected_request)
    end

    it 'marks the request as complete if record_requests is disabled' do
      allow(Billy::config).to receive(:record_requests).and_return(false)
      expect(request_log.complete(nil, :handler, cache_key)).to be_nil
    end
  end

  describe '#requests' do
    it 'returns an empty array when there are no requests' do
      expect(request_log.requests).to be_empty
    end

    it 'returns the currently known requests' do
      allow(Billy::config).to receive(:record_requests).and_return(true)

      request1 = request_log.record(:method, :url, :headers, :body, cache_scope)
      request2 = request_log.record(:method, :url, :headers, :body, cache_scope)
      expect(request_log.requests).to eql([request1, request2])
    end
  end

  describe '#reset' do
    it 'resets known requests' do
      allow(Billy::config).to receive(:record_requests).and_return(true)

      request1 = request_log.record(:method, :url, :headers, :body, cache_scope)
      request2 = request_log.record(:method, :url, :headers, :body, cache_scope)
      expect(request_log.requests).to eql([request1, request2])

      request_log.reset
      expect(request_log.requests).to be_empty
    end
  end
end
