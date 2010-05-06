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


    def domain_check_process_with_afnic(xml) # :nodoc:
      ret = domain_check_process_without_afnic(xml)
      xml.xpath('epp:extension/frnic:ext/frnic:resData/frnic:chkData/frnic:domain/frnic:cd', SCHEMAS_URL).each do |dom|
	name = dom.xpath('frnic:name', SCHEMAS_URL)
	hash = ret.select {|d| d[:name] == name.text}.first
	hash[:reserved] = name.attr('reserved').value == "1"
	unless (reason = dom.xpath('frnic:rsvReason', SCHEMAS_URL).text).empty?
	  hash[:rsvReason] = reason
	end
	hash[:forbidden] = name.attr('forbidden').value == "1"
	unless (reason = dom.xpath('frnic:fbdReason', SCHEMAS_URL).text).empty?
	  hash[:fbdReason] = reason
	end
      end
      return ret
    end
    alias_method :domain_check_process_without_afnic, :domain_check_process
    alias_method :domain_check_process, :domain_check_process_with_afnic
  end
end
