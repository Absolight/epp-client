# $Abso$

require 'openssl'
require 'socket'
require 'nokogiri'
require 'builder'

require 'epp-client/xml'
require 'epp-client/session'
require 'epp-client/connection'
require 'epp-client/exceptions'

class EPPClient
  include XML
  include Session
  include Connection

  HG_KEYWORD = %w$Abso$

  SCHEMAS = %w[
    epp-1.0
    domain-1.0
    host-1.0
    contact-1.0
    secDNS-1.0
  ]

  SCHEMAS_URL = SCHEMAS.inject({}) do |a,s|
    a[s.sub(/-1\.0$/, '')] = "urn:ietf:params:xml:ns:#{s}" if s =~ /-1\.0$/
    a[s] = "urn:ietf:params:xml:ns:#{s}"
    a
  end

  attr_accessor :login, :password, :server, :port, :services, :lang, :extensions, :version, :context, :clTRID

  # ==== Required Attrbiutes
  #
  # * <tt>:server</tt> - The EPP server to connect to
  # * <tt>:login</tt> - The tag or username used with <tt><login></tt> requests.
  # * <tt>:password</tt> - The password used with <tt><login></tt> requests.
  #
  # ==== Optional Attributes
  #
  # * <tt>:port</tt> - The EPP standard port is 700. However, you can choose a
  #   different port to use.
  # * <tt>:clTRID</tt> - The client transaction identifier is an element that
  #   EPP specifies MAY be used to uniquely identify the command to the server.
  #   You are responsible for maintaining your own transaction identifier space
  #   to ensure uniqueness. Defaults to "test-<pid>-<random>"
  # * <tt>:lang</tt> - Set custom language attribute. Default is 'en'.
  # * <tt>:services</tt> - Use custom EPP services in the <login> frame. The
  #   defaults use the EPP standard domain, contact and host 1.0 services.
  # * <tt>:extensions</tt> - URLs to custom extensions to standard EPP. Use
  #   these to extend the standard EPP (e.g., Nominet uses extensions).
  #   Defaults to none.
  # * <tt>:version</tt> - Set the EPP version. Defaults to "1.0".
  def initialize(attrs)
    unless attrs.key?(:server) && attrs.key?(:login) && attrs.key?(:password)
      raise ArgumentError, "server, login and password are required"
    end

    attrs.each do |k,v|
      begin
	self.send("#{k}=", v)
      rescue NoMethodError
	raise ArgumentError, "there is no #{k} argument"
      end
    end

    @port ||= 700
    @lang ||= "en"
    @services ||= SCHEMAS_URL.values_at('domain', 'contact', 'host')
    @extensions ||= []
    @version ||= "1.0"
    @clTRID ||= "test-#{$$}-#{rand(1000)}"

    @context ||= OpenSSL::SSL::SSLContext.new

    @logged_in = false
  end
end
