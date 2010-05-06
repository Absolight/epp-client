# $Abso$

require 'epp-client'

class EPPClient
  class SmallRegistry < EPPClient
    HG_KEYWORD << %q$Abso$

    SCHEMAS_SR = %w[
      sr-1.0
    ]

    SCHEMAS_URL.merge!(SCHEMAS_SR.inject({}) do |a,s|
      a[s.sub(/-1\.0$/, '')] = "https://www.smallregistry.net/schemas/#{s}.xsd" if s =~ /-1\.0$/
      a[s] = "https://www.smallregistry.net/schemas/#{s}.xsd"
      a
    end)

    #
    # Sets the default for Smallregistry, that is, server and port, according
    # to Smallregistry's documentation.
    # https://www.smallregistry.net/faqs/quelles-sont-les-specificites-du-serveur-epp
    #
    # ==== Required Attributes
    #
    # * <tt>:client_id</tt> - The tag or username used with <tt><login></tt> requests.
    # * <tt>:password</tt> - The password used with <tt><login></tt> requests.
    # * <tt>:ssl_cert</tt> - The file containing the client certificate.
    # * <tt>:ssl_key</tt> - The file containing the key of the certificate.
    #
    # ==== Optional Attributes 
    # * <tt>:test</tt> - sets the server to be the test server.
    #
    # See EPPClient for other attributes.
    def initialize(attrs)
      unless attrs.key?(:client_id) && attrs.key?(:password) && attrs.key?(:ssl_cert) && attrs.key?(:ssl_key)
	raise ArgumentError, "client_id, password, ssl_cert and ssl_key are required"
      end
      if attrs.delete(:test) == true
	attrs[:server] ||= 'epp.test.smallregistry.net'
	attrs[:port] ||= 2700
      else
	attrs[:server] ||= 'epp.smallregistry.net'
	attrs[:port] ||= 700
      end
      super(attrs)
      @extensions << SCHEMAS_URL['sr']
    end
  end
end
