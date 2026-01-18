require 'spec_helper'

describe Billy::RequestHandler do
  subject { Billy::RequestHandler.new }

  it 'implements Handler' do
    expect(subject).to be_a Billy::Handler
  end

  describe '#handlers' do
    it 'has a stub handler' do
      expect(subject.handlers[:stubs]).to be_a Billy::StubHandler
    end

    it 'has a cache handler' do
      expect(subject.handlers[:cache]).to be_a Billy::CacheHandler
    end

    it 'has a proxy handler' do
      expect(subject.handlers[:proxy]).to be_a Billy::ProxyHandler
    end
  end

  context 'with stubbed handlers' do
    let(:args) { %w(get url headers body) }
    let(:cache_scope) { 0 }
    let(:args_with_scope) { args + [cache_scope] }
    let(:stub_response) { { status: 200, headers: {}, content: 'foo', cache_key: nil } }
    let(:cache_response) { { status: 200, headers: {}, content: 'bar', cache_key: nil } }
    let(:proxy_response) { { status: 200, headers: {}, content: 'baz', cache_key: nil } }
    let(:stub_handler) { double('StubHandler') }
    let(:cache_handler) { double('CacheHandler') }
    let(:proxy_handler) { double('ProxyHandler') }
    let(:handlers) do
      {
        stubs: stub_handler,
        cache: cache_handler,
        proxy: proxy_handler
      }
    end

    before do
      allow(subject).to receive(:handlers).and_return(handlers)
    end

    describe '#handles_request?' do
      it 'returns false if no handlers handle the request' do
        handlers.each do |_key, handler|
          expect(handler).to_not receive(:handles_request?)
        end
        expect(subject.handles_request?(*args)).to be false
      end

      it 'returns true immediately if the stub handler handles the request' do
        expect(stub_handler).to_not receive(:handles_request?)
        expect(cache_handler).to_not receive(:handles_request?)
        expect(proxy_handler).to_not receive(:handles_request?)
        expect(subject.handles_request?(*args)).to be false
      end

      it 'returns true if the cache handler handles the request' do
        expect(stub_handler).to_not receive(:handles_request?)
        expect(cache_handler).to_not receive(:handles_request?)
        expect(proxy_handler).to_not receive(:handles_request?)
        expect(subject.handles_request?(*args)).to be false
      end

      it 'returns true if the proxy handler handles the request' do
        expect(stub_handler).to_not receive(:handles_request?)
        expect(cache_handler).to_not receive(:handles_request?)
        expect(proxy_handler).to_not receive(:handles_request?)
        expect(subject.handles_request?(*args)).to be false
      end
    end

    describe '#handle_request' do
      before do
        allow(Billy::config).to receive(:record_requests).and_return(true)
      end

      it 'returns stubbed responses' do
        expect(stub_handler).to receive(:handle_request).with(*args_with_scope).and_return(stub_response)
        expect(cache_handler).to_not receive(:handle_request)
        expect(proxy_handler).to_not receive(:handle_request)
        expect(subject.handle_request(*args)).to eql stub_response
        expect(subject.requests).to eql([{status: :complete, handler: :stubs, method: 'get', url: 'url', headers: 'headers', body: 'body', scope: cache_scope, cache_key: nil}])
      end

      it 'returns cached responses' do
        expect(stub_handler).to receive(:handle_request).with(*args_with_scope)
        expect(cache_handler).to receive(:handle_request).with(*args_with_scope).and_return(cache_response)
        expect(proxy_handler).to_not receive(:handle_request)
        expect(subject.handle_request(*args)).to eql cache_response
        expect(subject.requests).to eql([{status: :complete, handler: :cache, method: 'get', url: 'url', headers: 'headers', body: 'body', scope: cache_scope, cache_key: nil}])
      end

      it 'returns proxied responses' do
        expect(stub_handler).to receive(:handle_request).with(*args_with_scope)
        expect(cache_handler).to receive(:handle_request).with(*args_with_scope)
        expect(proxy_handler).to receive(:handle_request).with(*args_with_scope).and_return(proxy_response)
        expect(subject.handle_request(*args)).to eql proxy_response
        expect(subject.requests).to eql([{status: :complete, handler: :proxy, method: 'get', url: 'url', headers: 'headers', body: 'body', scope: cache_scope, cache_key: nil}])
      end

      it 'returns an error hash if request is not handled' do
        expect(stub_handler).to receive(:handle_request).with(*args_with_scope)
        expect(cache_handler).to receive(:handle_request).with(*args_with_scope)
        expect(proxy_handler).to receive(:handle_request).with(*args_with_scope)
        expect(subject.handle_request(*args)).to eql(error: 'Connection to url not cached and new http connections are disabled')
        expect(subject.requests).to eql([{status: :complete, handler: :error, method: 'get', url: 'url', headers: 'headers', body: 'body', scope: cache_scope, cache_key: nil}])
      end

      it 'returns an error hash with body message if request cached based on body is not handled' do
        args[0] = Billy.config.cache_request_body_methods[0]
        expect(stub_handler).to receive(:handle_request).with(*args_with_scope)
        expect(cache_handler).to receive(:handle_request).with(*args_with_scope)
        expect(proxy_handler).to receive(:handle_request).with(*args_with_scope)
        expect(subject.handle_request(*args)).to eql(error: "Connection to url with body 'body' not cached and new http connections are disabled")
        expect(subject.requests).to eql([{status: :complete, handler: :error, method: 'post', url: 'url', headers: 'headers', body: 'body', scope: cache_scope, cache_key: nil}])
      end

      it 'returns an error hash on unhandled exceptions' do
        # Allow handling requests initially
        allow(stub_handler).to receive(:handle_request)
        allow(cache_handler).to receive(:handle_request)

        allow(proxy_handler).to receive(:handle_request).and_raise("Any Proxy Error")
        expect(subject.handle_request(*args)).to eql(error: "Any Proxy Error")

        allow(cache_handler).to receive(:handle_request).and_raise("Any Cache Error")
        expect(subject.handle_request(*args)).to eql(error: "Any Cache Error")

        allow(stub_handler).to receive(:handle_request).and_raise("Any Stub Error")
        expect(subject.handle_request(*args)).to eql(error: "Any Stub Error")
      end
    end

    describe '#stubs' do
      it 'delegates to the stub_handler' do
        expect(stub_handler).to receive(:stubs)
        subject.stubs
      end
    end

    describe '#stub' do
      it 'delegates to the stub_handler' do
        expect(stub_handler).to receive(:stub).with('some args')
        subject.stub('some args')
      end
    end

    describe '#reset' do
      it 'resets all of the handlers' do
        handlers.each do |_key, handler|
          expect(handler).to receive(:reset)
        end
        expect(subject.request_log).to receive(:reset)
        subject.reset
      end
    end

    describe '#reset_stubs' do
      it 'resets the stub handler' do
        expect(stub_handler).to receive(:reset)
        subject.reset_stubs
      end
    end

    describe '#reset_cache' do
      it 'resets the cache handler' do
        expect(cache_handler).to receive(:reset)
        subject.reset_cache
      end
    end

    describe '#restore_cache' do
      it 'resets the cache handler' do
        expect(cache_handler).to receive(:reset)
        subject.reset_cache
      end
    end
  end
end
