# frozen_string_literal: true

require 'spec_helper'

describe Billy::ProxyConnection do
  describe '#prepare_response_headers_for_evma_httpserver' do
    let(:subject) { described_class.new('') }

    it 'removes duplicated headers fields' do
      provided_headers = {
        'transfer-encoding' => '',
        'content-length' => '',
        'content-encoding' => '',
        'key' => 'value'
      }
      expected_headers = { 'key' => 'value' }
      headers = subject.send(:prepare_response_headers_for_evma_httpserver, provided_headers)

      expect(headers).to eql expected_headers
    end
  end
end
