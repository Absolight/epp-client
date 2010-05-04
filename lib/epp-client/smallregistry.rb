# $Abso$

require 'epp-client'

class EPPClient
  class SmallRegistry < EPPClient
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
    #
    # ==== Optional Attributes 
    # * <tt>:test</tt> - sets the server to be the test server.
    def initialize(args)
      if args.delete(:test) == true
	args[:server] ||= 'epp.test.smallregistry.net'
	args[:port] ||= 2700
      else
	args[:server] ||= 'epp.smallregistry.net'
	args[:port] ||= 700
      end
      super(args)
      @extensions << SCHEMAS_URL['sr']
    end
  end
end
