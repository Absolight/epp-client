module EPPClient
  module SSL
    attr_reader :ssl_cert, :ssl_key

    def ssl_key=(key) #:nodoc:
      case key
      when OpenSSL::PKey::RSA
        @ssl_key = key
      when String
        key = File.read(key) unless key =~ /-----BEGIN RSA PRIVATE KEY-----/
        @ssl_key = OpenSSL::PKey::RSA.new(key)
      else
        fail ArgumentError, 'Must either be an OpenSSL::PKey::RSA object, a filename or a key'
      end
    end

    def ssl_cert=(cert) #:nodoc:
      case cert
      when OpenSSL::X509::Certificate
        @ssl_cert = cert
      when String
        cert = File.read(cert) unless cert =~ /-----BEGIN CERTIFICATE-----/
        @ssl_cert = OpenSSL::X509::Certificate.new(cert)
      else
        fail ArgumentError, 'Must either be an OpenSSL::X509::Certificate object, a filename or a certificate'
      end
    end

    def open_connection # :nodoc:
      @context.cert ||= ssl_cert if ssl_cert.is_a?(OpenSSL::X509::Certificate)
      @context.key ||= ssl_key if ssl_key.is_a?(OpenSSL::PKey::RSA)
      super
    end
  end
end
