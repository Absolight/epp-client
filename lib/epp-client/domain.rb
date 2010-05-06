# $Abso$

class EPPClient
  module Domain
    def domain_check_xml(*domains) # :nodoc:
      command do |xml|
	xml.check do
	  xml.check('xmlns' => SCHEMAS_URL['domain-1.0']) do
	    domains.each do |dom|
	      xml.name(dom)
	    end
	  end
	end
      end
    end

    # Check the availability of a domain
    #
    # takes an array of domains as arguments
    #
    # returns an array of hashes containing three fields :
    # * <tt>:name</tt> - The domain name
    # * <tt>:avail</tt> - Wether the domain is available or not.
    # * <tt>:reason</tt> - The reason for non availability, if given.
    def domain_check(*domains)
      domains.flatten!
      response = send_request(domain_check_xml(*domains))

      get_result(:xml => response, :callback => :domain_check_process)
    end

    def domain_check_process(xml) # :nodoc:
      xml.xpath('epp:resData/domain:chkData/domain:cd', SCHEMAS_URL).inject([]) do |acc, dom|
	ret = {
	  :name => dom.xpath('domain:name', SCHEMAS_URL).text,
	  :avail => dom.xpath('domain:name', SCHEMAS_URL).attr('avail').value == '1',
	}
	unless (reason = dom.xpath('domain:reason', SCHEMAS_URL).text).empty?
	  ret[:reason] = reason
	end
	acc << ret
      end
    end
  end
end
