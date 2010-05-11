# $Abso$

require 'epp-client'

class EPPClient
  class AFNIC < EPPClient
    HG_KEYWORD << %q$Abso$

    SCHEMAS_AFNIC = %w[
      frnic-1.0
    ]

    SCHEMAS_URL.merge!(SCHEMAS_AFNIC.inject({}) do |a,s|
      a[s.sub(/-1\.0$/, '')] = "http://www.afnic.fr/xml/epp/#{s}" if s =~ /-1\.0$/
      a[s] = "http://www.afnic.fr/xml/epp/#{s}"
      a
    end).merge!(SCHEMAS_RGP.inject({}) do |a,s|
      a[s.sub(/-1\.0$/, '')] = "urn:ietf:params:xml:ns:#{s}" if s =~ /-1\.0$/
      a[s] = "urn:ietf:params:xml:ns:#{s}"
      a
    end)


    # Sets the default for AFNIC, that is, server and port, according to
    # AFNIC's documentation.
    # http://www.afnic.fr/doc/interface/epp
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
      @extensions << SCHEMAS_URL['frnic'] << SCHEMAS_URL['rgp']
    end


    def domain_check_process(xml) # :nodoc:
      ret = super
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

    def domain_info_process(xml) #:nodoc:
      ret = super
      if (rgp_status = xml.xpath('epp:extension/rgp:infData/rgp:rgpStatus', SCHEMAS_URL)).size > 0
	ret[:status] += rgp_status.map {|s| s.attr('s')}
      end
      if (frnic_status = xml.xpath('epp:extension/frnic:ext/frnic:resData/frnic:infData/frnic:domain/frnic:status', SCHEMAS_URL)).size > 0
	ret[:status] += frnic_status.map {|s| s.attr('s')}
      end
      ret
    end

    def contact_info_process(xml) #:nodoc:
      ret = super
      if (contact = xml.xpath('epp:extension/frnic:ext/frnic:resData/frnic:infData/frnic:contact', SCHEMAS_URL)).size > 0
	if (list = contact.xpath('frnic:list', SCHEMAS_URL)).size > 0
	  ret[:list] = list.map {|l| l.text}
	end
	if (firstName = contact.xpath('frnic:firstName', SCHEMAS_URL)).size > 0
	  ret[:firstName] = firstName.text
	end
	if (iI = contact.xpath('frnic:individualInfos', SCHEMAS_URL)).size > 0
	  ret[:individualInfos] = {}
	  ret[:individualInfos][:birthDate] = Date.parse(iI.xpath('frnic:birthDate', SCHEMAS_URL).text)
	  %w(idStatus birthCity birthPc birthCc).each do |val|
	    if (r = iI.xpath("frnic:#{val}", SCHEMAS_URL)).size > 0
	      ret[:individualInfos][val.to_sym] = r.text
	    end
	  end
	end
	if (leI = contact.xpath('frnic:legalEntityInfos', SCHEMAS_URL)).size > 0
	  ret[:legalEntityInfos] = {}
	  ret[:legalEntityInfos][:legalStatus] = leI.xpath('frnic:legalStatus', SCHEMAS_URL).attr('s').value
	  %w(idStatus siren VAT trademark).each do |val|
	    if (r = leI.xpath("frnic:#{val}", SCHEMAS_URL)).size > 0
	      ret[:legalEntityInfos][val.to_sym] = r.text
	    end
	  end
	  if (asso = leI.xpath("frnic:asso", SCHEMAS_URL)).size > 0
	    ret[:legalEntityInfos][:asso] = {}
	    if (r = asso.xpath("frnic:waldec", SCHEMAS_URL)).size > 0
	      ret[:legalEntityInfos][:asso][:waldec] = r.text
	    else
	      ret[:legalEntityInfos][:asso][:decl] = Date.parse(asso.xpath('frnic:decl', SCHEMAS_URL).text)
	      publ = asso.xpath('frnic:publ', SCHEMAS_URL)
	      ret[:legalEntityInfos][:asso][:publ] = {
		:date => Date.parse(publ.text),
		:announce => publ.attr('announce').value,
		:page => publ.attr('page').value,
	      }
	    end
	  end
	end
      end
      ret
    end

    def contact_create_xml(contact) #:nodoc:
      ret = super

      ext = extension do |xml|
	xml.ext( :xmlns => SCHEMAS_URL['frnic']) do
	  xml.create do
	    xml.contact do
	      if contact.key?(:legalEntityInfos)
		lEI = contact[:legalEntityInfos]
		xml.legalEntityInfos do
		  xml.legalStatus(:s => lEI[:legalStatus])
		  [:siren, :VAT, :trademark].each do |val|
		    if lEI.key?(val)
		      xml.__send__(val, lEI[val])
		    end
		  end
		  if lEI.key?(:asso)
		    asso = lEI[:asso]
		    xml.asso do
		      if asso.key?(:waldec)
			xml.waldec(asso[:waldec])
		      else
			xml.decl(asso[:decl])
			xml.publ({:announce => asso[:publ][:announce], :page => asso[:publ][:page]}, asso[:publ][:date])
		      end
		    end
		  end
		end
	      else
		if contact.key?(:list)
		  xml.list(contact[:list])
		end
		if contact.key?(:individualInfos)
		  iI = contact[:individualInfos]
		  xml.individualInfos do
		    xml.birthDate(iI[:birthDate])
		    if iI.key?(:birthCity)
		      xml.birthCity(iI[:birthCity])
		    end
		    if iI.key?(:birthPc)
		      xml.birthPc(iI[:birthPc])
		    end
		    xml.birthCc(iI[:birthCc])
		  end
		end
		if contact.key?(:firstName)
		  xml.firstName(contact[:firstName])
		end
	      end
	    end
	  end
	end
      end

      insert_extension(ret, ext)
    end

    def contact_create_process(xml) #:nodoc:
      ret = super
      if (creData = xml.xpath('epp:extension/frnic:ext/frnic:resData/frnic:creData', SCHEMAS_URL)).size > 0
	ret[:nhStatus] = creData.xpath('frnic:nhStatus', SCHEMAS_URL).attr('new').value == '1'
	ret[:idStatus] = creData.xpath('frnic:idStatus', SCHEMAS_URL).text
      end
      ret
    end

  end
end
