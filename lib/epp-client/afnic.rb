# $Abso$

require 'epp-client'

class EPPClient
  class AFNIC < EPPClient
    SCHEMAS_AFNIC = %w[
      frnic-1.0
    ]

    SCHEMAS_URL.merge!(SCHEMAS_AFNIC.inject({}) do |a,s|
      a[s.sub(/-1\.0$/, '')] = "http://www.afnic.fr/xml/epp/#{s}" if s =~ /-1\.0$/
      a[s] = "http://www.afnic.fr/xml/epp/#{s}"
      a
    end)

    # Sets the default for AFNIC, that is, server and port, according to
    # AFNIC's documentation.
    #
    # ==== Optional Attributes 
    # * <tt>:test</tt> - sets the server to be the test server.
    def initialize(args)
      if args.delete(:test) == true
	args[:server] ||= 'epp.test.nic.fr'
      else
	args[:server] ||= 'epp.nic.fr'
      end
      args[:port] ||= 700
      super(args)
      @extensions << SCHEMAS_URL['frnic']
    end
  end
end
