# $Abso$

require 'openssl'
require 'socket'
require 'nokogiri'
require 'builder'
require 'date'

require 'epp-client/xml'
require 'epp-client/session'
require 'epp-client/connection'
require 'epp-client/exceptions'
require 'epp-client/ssl'
require 'epp-client/domain'
require 'epp-client/contact'

class EPPClient
  HG_KEYWORD = [%q$Abso$]

  include XML
  include Session
  include Connection
  include SSL
  include Domain
  include Contact

  SCHEMAS = %w[
    epp-1.0
    domain-1.0
    host-1.0
    contact-1.0
    secDNS-1.0
  ]
  SCHEMAS_RGP = %w[
    rgp-1.0
  ]

  SCHEMAS_URL = SCHEMAS.inject({}) do |a,s|
    a[s.sub(/-1\.0$/, '')] = "urn:ietf:params:xml:ns:#{s}" if s =~ /-1\.0$/
    a[s] = "urn:ietf:params:xml:ns:#{s}"
    a
  end

  attr_accessor :client_id, :password, :server, :port, :services, :lang, :extensions, :version, :context, :clTRID

  # ==== Required Attributes
  #
  # [<tt>:server</tt>] The EPP server to connect to
  # [<tt>:client_id</tt>]
  #   The tag or username used with <tt><login></tt> requests.
  # [<tt>:password</tt>] The password used with <tt><login></tt> requests.
  #
  # ==== Optional Attributes
  #
  # [<tt>:port</tt>]
  #   The EPP standard port is 700. However, you can choose a different port to
  #   use.
  # [<tt>:clTRID</tt>]
  #   The client transaction identifier is an element that EPP specifies MAY be
  #   used to uniquely identify the command to the server. The string
  #   "-<index>" will be added to it, index being incremented at each command.
  #   Defaults to "test-<pid>-<random>"
  # [<tt>:lang</tt>] Set custom language attribute. Default is 'en'.
  # [<tt>:services</tt>]
  #   Use custom EPP services in the <login> frame. The defaults use the EPP
  #   standard domain, contact and host 1.0 services.
  # [<tt>:extensions</tt>]
  #   URLs to custom extensions to standard EPP. Use these to extend the
  #   standard EPP (e.g., AFNIC, smallregistry uses extensions). Defaults to
  #   none.
  # [<tt>:version</tt>] Set the EPP version. Defaults to "1.0".
  # [<tt>:ssl_cert</tt>] The file containing the client certificate.
  # [<tt>:ssl_key</tt>] The file containing the key of the certificate.
  def initialize(attrs)
    unless attrs.key?(:server) && attrs.key?(:client_id) && attrs.key?(:password)
      raise ArgumentError, "server, client_id and password are required"
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
    @clTRID_index = 0

    @context ||= OpenSSL::SSL::SSLContext.new

    @logged_in = false
  end

  def clTRID # :nodoc:
    @clTRID_index += 1
    @clTRID + "-#{@clTRID_index}"
  end
end
