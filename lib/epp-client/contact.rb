# $Abso$

class EPPClient
  module Contact
    HG_KEYWORD_Contact = %q$Abso$
    def self.included(base) # :nodoc:
      base.class_eval do
	HG_KEYWORD << HG_KEYWORD_Contact
      end
    end

    def contact_check_xml(*contacts) #:nodoc:
      command do |xml|
	xml.check do
	  xml.check('xmlns' => SCHEMAS_URL['contact-1.0']) do
	    contacts.each do |c|
	      xml.id(c)
	    end
	  end
	end
      end
    end

    def contact_check(*contacts)
      contacts.flatten!

      response = send_request(contact_check_xml(*contacts))
      get_result(:xml => response, :callback => :contact_check_process)
    end

    def contact_check_process(xml) #:nodoc:
      xml.xpath('epp:resData/contact:chkData/contact:cd', SCHEMAS_URL).map do |dom|
	ret = {
	  :name => dom.xpath('contact:id', SCHEMAS_URL).text,
	  :avail => dom.xpath('contact:id', SCHEMAS_URL).attr('avail').value == '1',
	}
	unless (reason = dom.xpath('contact:reason', SCHEMAS_URL).text).empty?
	  ret[:reason] = reason
	end
	ret
      end
    end

    def contact_info_xml(args) #:nodoc:
      command do |xml|
	xml.info do
	  xml.info('xmlns' => SCHEMAS_URL['contact-1.0']) do
	    xml.id(args[:id])
	    if args.key?(:authinfo)
	      xml.authInfo do
		xml.pw(args[:authinfo])
	      end
	    end
	  end
	end
      end
    end

    def contact_info(args)
      if String === args
	args = {:id => args}
      end
      response = send_request(contact_info_xml(args))

      get_result(:xml => response, :callback => :contact_info_process)
    end

    def contact_info_process(xml) #:nodoc:
      contact = xml.xpath('epp:resData/contact:infData', SCHEMAS_URL)
      ret = {
	:id => contact.xpath('contact:id', SCHEMAS_URL).text,
	:roid => contact.xpath('contact:roid', SCHEMAS_URL).text,
      }
      if (status = contact.xpath('contact:status', SCHEMAS_URL)).size > 0
	ret[:status] = status.map {|s| s.attr('s')}
      end

      if (postalInfo = contact.xpath('contact:postalInfo', SCHEMAS_URL)).size > 0
	ret[:postalInfo] = postalInfo.inject({}) do |acc, p|
	  type = p.attr('type')
	  acc[type] = { :name => p.xpath('contact:name', SCHEMAS_URL).text, :addr => {} }
	  if (org = p.xpath('contact:org', SCHEMAS_URL)).size > 0
	    acc[type][:org] = org.text
	  end
	  addr = p.xpath('contact:addr', SCHEMAS_URL)

	  acc[type][:addr][:street] = addr.xpath('contact:street', SCHEMAS_URL).map {|s| s.text}
	  %w(city cc).each do |val|
	    acc[type][:addr][val.to_sym] = addr.xpath("contact:#{val}", SCHEMAS_URL).text
	  end
	  %w(sp pc).each do |val|
	    if (r = addr.xpath("contact:#{val}", SCHEMAS_URL)).size > 0
	      acc[type][:addr][val.to_sym] = r.text
	    end
	  end

	  acc
	end
      end

      %w(voice fax email clID crID upID).each do |val|
	if (value = contact.xpath("contact:#{val}", SCHEMAS_URL)).size > 0
	  ret[val.to_sym] = value.text
	end
      end
      %w(crDate upDate trDate).each do |val|
	if (date = contact.xpath("contact:#{val}", SCHEMAS_URL)).size > 0
	  ret[val.to_sym] = DateTime.parse(date.text)
	end
      end
      if (authInfo = contact.xpath('contact:authInfo', SCHEMAS_URL)).size > 0
	ret[:authInfo_pw] = authInfo.xpath('contact:pw', SCHEMAS_URL).text
      end
      if (disclose = contact.xpath('contact:disclose', SCHEMAS_URL)).size > 0
	ret[:disclose] = { :flag => disclose.attr('flag').value == '1', :elements => [] }
	disclose.children.each do |c|
	  r = { :name => c.name }
	  unless (type = c.attr('type').value).nil?
	    r[:type] == type
	  end
	  ret[:disclose][:elements] << r
	end
      end
      ret
    end
  end
end
