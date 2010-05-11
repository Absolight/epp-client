# $Abso$

class EPPClient
  module Domain
    HG_KEYWORD_Domain = %q$Abso$
    def self.included(base) # :nodoc:
      base.class_eval do
	HG_KEYWORD << HG_KEYWORD_Domain
      end
    end

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
      xml.xpath('epp:resData/domain:chkData/domain:cd', SCHEMAS_URL).map do |dom|
	ret = {
	  :name => dom.xpath('domain:name', SCHEMAS_URL).text,
	  :avail => dom.xpath('domain:name', SCHEMAS_URL).attr('avail').value == '1',
	}
	unless (reason = dom.xpath('domain:reason', SCHEMAS_URL).text).empty?
	  ret[:reason] = reason
	end
	ret
      end
    end

    def domain_info_xml(args) # :nodoc:
      command do |xml|
	xml.info do
	  xml.info('xmlns' => SCHEMAS_URL['domain-1.0']) do
	    xml.name(args[:name])
	    if args.key?(:authInfo)
	      xml.authInfo do
		if args.key?(:roid)
		  xml.pw({:roid => args[:roid]}, args[:authInfo])
		else
		  xml.pw(args[:authInfo])
		end
	      end
	    end
	  end
	end
      end
    end

    # Returns the informations about a domain
    #
    # Takes either a unique argument, a string, representing the domain, or a
    # hash with : <tt>:name</tt> the domain name, and optionnaly
    # <tt>:authInfo</tt> the authentication information and possibly
    # <tt>:roid</tt> the contact the authInfo is about.
    #
    # Returned is a hash mapping as closely as possible the result expected
    # from the command as per Section 3.1.2 of RFC 5731
    def domain_info(args)
      if String === args
	args = {:name => args}
      end
      response = send_request(domain_info_xml(args))

      get_result(:xml => response, :callback => :domain_info_process)
    end

    def domain_info_process(xml) # :nodoc:
      dom = xml.xpath('epp:resData/domain:infData', SCHEMAS_URL)
      ret = {
	:name => dom.xpath('domain:name', SCHEMAS_URL).text,
	:roid => dom.xpath('domain:roid', SCHEMAS_URL).text,
      }
      if (status = dom.xpath('domain:status', SCHEMAS_URL)).size > 0
	ret[:status] = status.map {|s| s.attr('s')}
      end
      if (registrant = dom.xpath('domain:registrant', SCHEMAS_URL)).size > 0
	ret[:registrant] = registrant.text
      end
      if (contact = dom.xpath('domain:contact', SCHEMAS_URL)).size > 0
	ret[:contacts] = contact.inject({}) do |a,c|
	  s = c.attr('type').to_sym
	  a[s] ||= []
	  a[s] << c.text
	  a
	end
      end
      if (ns = dom.xpath('domain:ns', SCHEMAS_URL)).size > 0
	if (hostObj = ns.xpath('domain:hostObj', SCHEMAS_URL)).size > 0
	  ret[:ns] = hostObj.map {|h| h.text}
	elsif (hostAttr = ns.xpath('domain:hostAttr', SCHEMAS_URL)).size > 0
	  ret[:ns] = hostAttr.map do |h|
	    r = { :hostName => h.xpath('domain:hostName', SCHEMAS_URL).text }
	    if (v4 = h.xpath('domain:hostAddr[@ip="v4"]', SCHEMAS_URL)).size > 0
	      r[:hostAddrv4] = v4.map {|v| v.text}
	    end
	    if (v6 = h.xpath('domain:hostAddr[@ip="v6"]', SCHEMAS_URL)).size > 0
	      r[:hostAddrv6] = v6.map {|v| v.text}
	    end
	    r
	  end
	end
      end
      if (host = dom.xpath('domain:host', SCHEMAS_URL)).size > 0
	ret[:host] = host.map {|h| h.text}
      end
      %w(clID upID).each do |val|
	if (r = dom.xpath("domain:#{val}", SCHEMAS_URL)).size > 0
	  ret[val.to_sym] = r.text
	end
      end
      %w(crDate exDate upDate trDate).each do |val|
	if (r = dom.xpath("domain:#{val}", SCHEMAS_URL)).size > 0
	  ret[val.to_sym] = DateTime.parse(r.text)
	end
      end
      if (authInfo = dom.xpath('domain:authInfo', SCHEMAS_URL)).size > 0
	ret[:authInfo] = authInfo.xpath('domain:pw', SCHEMAS_URL).text
      end
      return ret
    end

    def domain_create_xml(args) #:nodoc:
      command do |xml|
	xml.create do
	  xml.create('xmlns' => SCHEMAS_URL['domain-1.0']) do
	    xml.name args[:name]

	    if args.key?(:period)
	      xml.period({:unit => args[:period][:unit]}, args[:period][:number])
	    end

	    if args.key?(:ns)
	      xml.ns do
		if args[:ns].first.is_a?(Hash)
		  args[:ns].each do |ns|
		    xml.hostAttr do
		      xml.hostName ns[:hostName]
		      if ns.key?(:hostAddrv4)
			ns[:hostAddrv4].each do |v4|
			  xml.hostAddr({:ip => :v4}, v4)
			end
		      end
		      if ns.key?(:hostAddrv6)
			ns[:hostAddrv6].each do |v6|
			  xml.hostAddr({:ip => :v6}, v6)
			end
		      end
		    end
		  end
		else
		  args[:ns].each do |ns|
		    xml.hostObj ns
		  end
		end
	      end
	    end

	    xml.registrant args[:registrant] if args.key?(:registrant)

	    if args.key?(:contacts)
	      args[:contacts].each do |type,contacts|
		contacts.each do |c|
		  xml.contact({:type => type}, c)
		end
	      end
	    end

	    xml.authInfo do
	      xml.pw args[:authInfo]
	    end
	  end
	end
      end
    end

    # Creates a domain
    def domain_create(args)
      response = send_request(domain_create_xml(args))

      get_result(:xml => response, :callback => :domain_create_process)
    end

    def domain_create_process(xml) #:nodoc:
      dom = xml.xpath('epp:resData/domain:creData', SCHEMAS_URL)
      ret = {
	:name => dom.xpath('domain:name', SCHEMAS_URL).text,
	:crDate => DateTime.parse(dom.xpath('domain:crDate', SCHEMAS_URL).text),
	:upDate => DateTime.parse(dom.xpath('domain:crDate', SCHEMAS_URL).text),
      }
    end
  end
end
