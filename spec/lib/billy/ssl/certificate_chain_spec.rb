# frozen_string_literal: true

require 'spec_helper'

describe Billy::CertificateChain do
  let(:cert1) { Billy::Certificate.new('localhost') }
  let(:cert2) { Billy::Certificate.new('localhost.localdomain') }
  let(:chain) do
    described_class.new('localhost', cert1.cert, cert2.cert)
  end

  describe('#initialize') do
    it 'holds all certificates in order' do
      expect(chain.certificates).to eql([cert1.cert, cert2.cert])
    end

    it 'holds the domain' do
      expect(chain.domain).to eql('localhost')
    end
  end

  describe('#file') do
    it 'pass back the path' do
      expect(chain.file).to match(/chain-localhost.pem/)
    end

    it 'writes out all certificates' do
      chain.certificates.each do |cert|
        expect(File.read(chain.file)).to include(cert.to_pem)
      end
    end

    it 'creates a temporary file' do
      expect(File.exist?(chain.file)).to be(true)
    end

    it 'creates a PEM formatted certificate chain' do
      expect(File.read(chain.file)).to match(%r{^[A-Za-z0-9\-+/=]+$})
    end
  end
end
