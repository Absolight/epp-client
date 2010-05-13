# $Abso$

class EPPClient
  module Base

    attr_accessor :client_id, :password, :server, :port, :services, :lang, :extensions, :version, :context
    attr_writer :clTRID

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
end
