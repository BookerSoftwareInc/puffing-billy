# frozen_string_literal: true

require 'spec_helper'

describe Billy::ProxyRequestStub do
  describe '#matches?' do
    it 'matches urls and methods' do
      expect(described_class.new('http://example.com')
        .matches?('GET', 'http://example.com')).to be
      expect(described_class.new('http://example.com')
        .matches?('POST', 'http://example.com')).not_to be

      expect(described_class.new('http://example.com', method: :get)
        .matches?('GET', 'http://example.com')).to be
      expect(described_class.new('http://example.com', method: :post)
        .matches?('GET', 'http://example.com')).not_to be
      expect(described_class.new('http://example.com', method: :options)
        .matches?('GET', 'http://example.com')).not_to be

      expect(described_class.new('http://example.com', method: :post)
        .matches?('POST', 'http://example.com')).to be
      expect(described_class.new('http://fooxample.com', method: :post)
        .matches?('POST', 'http://example.com')).not_to be
      expect(described_class.new('http://fooxample.com', method: :options)
        .matches?('POST', 'http://example.com')).not_to be

      expect(described_class.new('http://example.com', method: :options)
        .matches?('OPTIONS', 'http://example.com')).to be
      expect(described_class.new('http://example.com', method: :options)
        .matches?('OPTIONS', 'http://zzzzzexample.com')).not_to be
      expect(described_class.new('http://example.com', method: :post)
        .matches?('OPTIONS', 'http://example.com')).not_to be
    end

    it 'matches regexps' do
      expect(described_class.new(%r{http://.+\.com}, method: :post)
        .matches?('POST', 'http://example.com')).to be
      expect(described_class.new(%r{http://.+\.co\.uk}, method: :get)
        .matches?('GET', 'http://example.com')).not_to be
    end

    it 'matches up to but not including query strings' do
      stub = described_class.new('http://example.com/foo/bar/')
      expect(stub.matches?('GET', 'http://example.com/foo/')).not_to be
      expect(stub.matches?('GET', 'http://example.com/foo/bar/')).to be
      expect(stub.matches?('GET', 'http://example.com/foo/bar/?baz=bap')).to be
    end

    it 'matches all methods' do
      expect(described_class.new('http://example.com', method: :all)
        .matches?('GET', 'http://example.com')).to be
      expect(described_class.new('http://example.com', method: :all)
        .matches?('POST', 'http://example.com')).to be
      expect(described_class.new('http://example.com', method: :all)
        .matches?('OPTIONS', 'http://example.com')).to be
      expect(described_class.new('http://example.com', method: :all)
        .matches?('HEAD', 'http://example.com')).to be
    end
  end

  describe '#matches? (with strip_query_params false in config)' do
    before do
      Billy.config.strip_query_params = false
    end

    it 'does not match up to request with query strings' do
      stub = described_class.new('http://example.com/foo/bar/')
      expect(stub.matches?('GET', 'http://example.com/foo/')).not_to be
      expect(stub.matches?('GET', 'http://example.com/foo/bar/')).to be
      expect(stub.matches?('GET', 'http://example.com/foo/bar/?baz=bap')).not_to be
    end
  end

  describe '#call (without #and_return)' do
    let(:subject) { described_class.new('url') }

    it 'returns a 204 empty response' do
      expect(subject.call('', '', {}, {}, nil)).to eql [204, { 'Content-Type' => 'text/plain' }, '']
    end
  end

  describe '#and_return + #call' do
    let(:subject) { described_class.new('url') }

    it 'generates bare responses' do
      subject.and_return body: 'baz foo bar'
      expect(subject.call('', '', {}, {}, nil)).to eql [
        200,
        {},
        'baz foo bar'
      ]
    end

    it 'generates text responses' do
      subject.and_return text: 'foo bar baz'
      expect(subject.call('', '', {}, {}, nil)).to eql [
        200,
        { 'Content-Type' => 'text/plain' },
        'foo bar baz'
      ]
    end

    it 'generates JSON responses' do
      subject.and_return json: { foo: 'bar' }
      expect(subject.call('', '', {}, {}, nil)).to eql [
        200,
        { 'Content-Type' => 'application/json' },
        '{"foo":"bar"}'
      ]
    end

    context 'JSONP' do
      it 'generates JSONP responses' do
        subject.and_return jsonp: { foo: 'bar' }
        expect(subject.call('', '', { 'callback' => ['baz'] }, {}, nil)).to eql [
          200,
          { 'Content-Type' => 'application/javascript' },
          'baz({"foo":"bar"})'
        ]
      end

      it 'generates JSONP responses with custom callback parameter' do
        subject.and_return jsonp: { foo: 'bar' }, callback_param: 'cb'
        expect(subject.call('', '', { 'cb' => ['bap'] }, {}, nil)).to eql [
          200,
          { 'Content-Type' => 'application/javascript' },
          'bap({"foo":"bar"})'
        ]
      end

      it 'generates JSONP responses with custom callback name' do
        subject.and_return jsonp: { foo: 'bar' }, callback: 'cb'
        expect(subject.call('', '', {}, {}, nil)).to eql [
          200,
          { 'Content-Type' => 'application/javascript' },
          'cb({"foo":"bar"})'
        ]
      end
    end

    it 'generates redirection responses' do
      subject.and_return redirect_to: 'http://example.com'
      expect(subject.call('', '', {}, {}, nil)).to eql [
        302,
        { 'Location' => 'http://example.com' },
        nil
      ]
    end

    it 'sets headers' do
      subject.and_return text: 'foo', headers: { 'HTTP-X-Foo' => 'bar' }
      expect(subject.call('', '', {}, {}, nil)).to eql [
        200,
        { 'Content-Type' => 'text/plain', 'HTTP-X-Foo' => 'bar' },
        'foo'
      ]
    end

    it 'sets status codes' do
      subject.and_return text: 'baz', code: 410
      expect(subject.call('', '', {}, {}, nil)).to eql [
        410,
        { 'Content-Type' => 'text/plain' },
        'baz'
      ]
    end

    it 'uses a callable' do
      expected_params = { 'param1' => ['one'], 'param2' => ['two'] }
      expected_headers = { 'header1' => 'three', 'header2' => 'four' }
      expected_body = 'body text'

      subject.and_return(proc do |params, headers, body, url, method|
        expect(params).to eql expected_params
        expect(headers).to eql expected_headers
        expect(body).to eql 'body text'
        expect(url).to eql 'url'
        expect(method).to eql 'GET'
        { code: 418, text: 'success' }
      end)
      expect(subject.call('GET', 'url', expected_params, expected_headers, expected_body)).to eql [
        418,
        { 'Content-Type' => 'text/plain' },
        'success'
      ]
    end

    it 'uses a callable with Billy.pass_request' do
      # Stub the proxy handler to avoid ArgumentError from cache_scope mismatch
      allow(Billy.proxy.request_handler.handlers[:proxy]).to receive(:handle_request).and_return(
        status: 200,
        headers: {},
        content: 'original'
      )

      EM.synchrony do
        subject.and_return(proc do |*args|
          response = Billy.pass_request(*args)
          response[:body] = 'modified'
          response[:code] = 205
          response
        end)

        url = 'http://google.com'

        # ProxyRequestStub#call returns [code, headers, body]
        expect(subject.call('GET', url, {}, {}, 'original')).to eql [
          205,
          {},
          'modified'
        ]
      end
    end
  end

  describe '#stub_requests' do
    let(:subject) { described_class.new('url') }

    before do
      Billy.config.record_stub_requests = true
    end

    it 'records requests' do
      subject.call('', '', {}, {}, nil)
      expect(subject.has_requests?).to be true
    end

    it 'records multiple requests' do
      expected_amount = 3
      expected_amount.times do
        subject.call('', '', {}, {}, nil)
      end

      expect(subject.requests.length).to eql expected_amount
    end

    it 'sets a request' do
      expected_request = {
        method: 'POST',
        url: 'test-url',
        params: { 'param1' => ['one'], 'param2' => ['two'] },
        headers: { 'header1' => 'three', 'header2' => 'four' },
        body: 'body text'
      }

      subject.call(
        expected_request[:method],
        expected_request[:url],
        expected_request[:params],
        expected_request[:headers],
        expected_request[:body]
      )
      expect(subject.requests[0]).to eql expected_request
    end
  end
end
