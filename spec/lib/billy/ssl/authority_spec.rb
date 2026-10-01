# frozen_string_literal: true

require 'spec_helper'

describe Billy::Authority do
  let(:auth1) { described_class.new }
  let(:auth2) { described_class.new }

  describe('#key') do
    it 'generates a new key each time' do
      expect(auth1.key).not_to be(auth2.key)
    end

    it 'generates 2048 bit keys' do
      expect(auth1.key.n.num_bytes * 8).to be(2048)
    end
  end

  describe('#cert') do
    it 'generates a new certificate each time' do
      expect(auth1.cert).not_to be(auth2.cert)
    end

    it 'generates unique serials' do
      expect(auth1.cert.serial).not_to be(auth2.cert.serial)
    end

    it 'configures a start date some days ago' do
      expect(auth1.cert.not_before).to \
        be_between((Date.today - 3).to_time, Date.today.to_time)
    end

    it 'configures an end date in some days' do
      expect(auth1.cert.not_after).to \
        be_between(Date.today.to_time, (Date.today + 3).to_time)
    end

    it 'configures the subject' do
      expect(auth1.cert.subject.to_s).to \
        eql('/CN=Puffing Billy/O=Puffing Billy')
    end

    it 'configures the certificate authority constrain' do
      expect(auth1.cert.extensions.first.to_s).to \
        eql('basicConstraints = critical, CA:TRUE')
    end

    it 'configures SSLv3' do
      # Zero-index version numbers. Yay.
      expect(auth1.cert.version).to be(2)
    end
  end

  describe('#key_file') do
    it 'pass back the path' do
      expect(auth1.key_file).to match(/ca.key$/)
    end

    it 'creates a temporary file' do
      expect(File.exist?(auth1.key_file)).to be(true)
    end

    it 'creates a PEM formatted certificate' do
      expect(File.read(auth1.key_file)).to match(%r{^[A-Za-z0-9\-+/=]+$})
    end

    it 'writes out a private key' do
      key = OpenSSL::PKey::RSA.new(File.read(auth1.key_file))
      expect(key.private?).to be(true)
    end
  end

  describe('#cert_file') do
    it 'pass back the path' do
      expect(auth1.cert_file).to match(/ca.crt$/)
    end

    it 'creates a temporary file' do
      expect(File.exist?(auth1.cert_file)).to be(true)
    end

    it 'creates a PEM formatted certificate' do
      expect(File.read(auth1.cert_file)).to match(%r{^[A-Za-z0-9\-+/=]+$})
    end
  end
end
