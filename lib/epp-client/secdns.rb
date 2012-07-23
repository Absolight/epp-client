module EPPClient
  module SecDNS
    SCHEMAS_SECDNS = %w[
      secDNS-1.1
    ]

    EPPClient::SCHEMAS_URL.merge!(SCHEMAS_SECDNS.inject({}) do |a,s|
      a[s.sub(/-1\.1$/, '')] = "urn:ietf:params:xml:ns:#{s}" if s =~ /-1\.1$/
      a[s] = "urn:ietf:params:xml:ns:#{s}"
      a
    end)

    def initialize(args)
      super
      @extensions << EPPClient::SCHEMAS_URL['secDNS-1.1']
    end

    # Extends the base domain info so that the specific secDNS elements
    # can be added.
    #
    # either:
    # [<tt>:keyData</tt>]
    #   containing an array of keyData objects with the following fields :
    #   [<tt>:flags</tt>]
    #     The flags field value as described in {section 2.1.1 of RFC
    #     4034}[http://tools.ietf.org/html/rfc4034#section-2.1.1].
    #   [<tt>:protocol</tt>]
    #     The protocol field value as described in {section 2.1.2 of RFC
    #     4034}[http://tools.ietf.org/html/rfc4034#section-2.1.2].
    #   [<tt>:alg</tt>]
    #     The algorithm number field value as described in {section 2.1.3 of RFC
    #     4034}[http://tools.ietf.org/html/rfc4034#section-2.1.3].
    #   [<tt>:pubKey</tt>]
    #     The encoded public key field value as described in {Section 2.1.4 of
    #     RFC 4034}[http://tools.ietf.org/html/rfc4034#section-2.1.4].
    # [<tt>:dsData</tt>]
    #   containing an array of dsData objects with the following fields :
    #   [<tt>:keyTag</tt>]
    #     The key tag value as described in {Section 5.1.1 of RFC
    #     4034}[http://tools.ietf.org/html/rfc4034#section-5.1.1].
    #   [<tt>:alg</tt>]
    #     The algorithm value as described in {Section 5.1.2 of RFC
    #     4034}[http://tools.ietf.org/html/rfc4034#section-5.1.2].
    #   [<tt>:digestType</tt>]
    #     The digest type value as described in {Section 5.1.3 of RFC
    #     4034}[http://tools.ietf.org/html/rfc4034#section-5.1.3].
    #   [<tt>:digest</tt>]
    #     The digest value as described in {Section 5.1.1 of RFC
    #     4034}[http://tools.ietf.org/html/rfc4034#section-5.1.1].
    #   [<tt>:keyData</tt>]
    #     An optional element that describes the key data used as input in the DS
    #     hash calculation for use in server validation. The <tt>:keyData</tt>
    #     element contains the child elements defined above.
    #
    # Optionnaly :
    # [<tt>:maxSigLife</tt>]
    #   An element that indicates a child's preference for the number of seconds
    #   after signature generation when the parent's signature on the DS
    #   information provided by the child will expire.
    def domain_info(domain)
      super # placeholder so that I can add some doc
    end

    def domain_info_process(xml) #:nodoc:
      ret = super
      ret_secdns = {}
      if (maxSigLife = xml.xpath('epp:extension/secDNS:infData/secDNS:maxSigLife', EPPClient::SCHEMAS_URL)).size > 0
	ret_secdns[:maxSigLife] = maxSigLife.text
      end
      ret_secdns[:dsData] = xml.xpath('epp:extension/secDNS:infData/secDNS:dsData', EPPClient::SCHEMAS_URL).map do |s|
	parse_ds_data(s)
      end
      ret_secdns[:keyData] = xml.xpath('epp:extension/secDNS:infData/secDNS:keyData', EPPClient::SCHEMAS_URL).map do |s|
	parse_key_data(s)
      end

      ret[:secDNS] = ret_secdns unless ret_secdns.values.reject {|v| v.nil?}.size == 0
      ret
    end

    # Extends the base domain create so that the specific secDNS create
    # informations can be sent, the additionnal informations are :
    #
    # either:
    # [<tt>:keyData</tt>]
    #   containing an array of keyData objects as described in the domain_info function.
    # [<tt>:dsData</tt>]
    #   containing an array of dsData objects as described in the domain_info function.
    #
    # Optionnaly :
    # [<tt>:maxSigLife</tt>]
    #   as described in the domain_info function.
    def domain_create(domain)
      super # placeholder so that I can add some doc
    end

    def domain_create_xml(domain) #:nodoc:
      ret = super

      if domain.key?(:maxSigLife) || domain.key?(:dsData) || domain.key?(:keyData)
	ext = extension do |xml|
	  xml.create( :xmlns => EPPClient::SCHEMAS_URL['secDNS']) do
	    if domain.key?(:maxSigLife)
	      xml.maxSigLife(domain[:maxSigLife])
	    end
	    if domain.key?(:dsData)
	      domain[:dsData].each do |ds|
		make_ds_data(xml, ds)
	      end
	    elsif domain.key?(:keyData)
	      domain[:keyData].each do |key|
		make_key_data(xml, key)
	      end
	    end
	  end
	end
	return insert_extension(ret, ext)
      else
	return ret
      end
    end

    # Extends the base domain update so that secDNS informations can be sent, the
    # additionnal informations are contained in an <tt>:secDNS</tt> object :
    #
    # [:rem]
    #   To remove keys or ds from the delegation, with possible attributes one of :
    #
    #   [<tt>:all</tt>]
    #     used to remove all DS and key data with a value of boolean true.  A
    #     value of boolean false will do nothing.  Removing all DS information
    #     can remove the ability of the parent to secure the delegation to the
    #     child zone.
    #   [<tt>:dsData</tt>]
    #     an array of dsData elements described in the domain_info function.
    #   [<tt>:keyData</tt>]
    #     an array of keyData elements as described in the domain_info function.
    #
    # [:add]
    #   To add keys or DS from the delegation, with possible attributes one of :
    #
    #   [<tt>:dsData</tt>]
    #     an array of dsData elements described in the domain_info function.
    #   [<tt>:keyData</tt>]
    #     an array of keyData elements as described in the domain_info function.
    # [:chg]
    #   contains security information to be changed, one of :
    #
    #   [:maxSigLife]
    #     optional, as described in the domain_info function.
    def domain_update(args)
      super # placeholder so that I can add some doc
    end

    def domain_update_xml(domain) #:nodoc:
      ret = super

      if domain.key?(:secDNS)
	sd = domain[:secDNS]
	ext = extension do |xml|
	  xml.update(sd[:urgent] == true ? {:urgent => true}: {}, {:xmlns => EPPClient::SCHEMAS_URL['secDNS']}) do
	    if sd.key?(:rem)
	      xml.rem do
		if sd[:rem].key?(:all) && sd[:rem][:all] == true
		  xml.all true
		elsif sd[:rem].key?(:dsData)
		  sd[:rem][:dsData].each do |ds|
		    make_ds_data(xml, ds)
		  end
		elsif sd[:rem].key?(:keyData)
		  sd[:rem][:keyData].each do |key|
		    make_key_data(xml, key)
		  end
		end
	      end
	    end
	    if sd.key?(:add)
	      xml.add do
		if sd[:add].key?(:dsData)
		  sd[:add][:dsData].each do |ds|
		    make_ds_data(xml, ds)
		  end
		elsif sd[:add].key?(:keyData)
		  sd[:add][:keyData].each do |key|
		    make_key_data(xml, key)
		  end
		end
	      end
	    end
	    if sd.key?(:chg) && sd[:chg].key?(:maxSigLife)
	      xml.chg do
		xml.maxSigLife sd[:chg][:maxSigLife]
	      end
	    end
	  end
	end
	return insert_extension(ret, ext)
      else
	return ret
      end
    end

    private
    def make_key_data(xml, key)
      xml.keyData do
	xml.flags key[:flags]
	xml.protocol key[:protocol]
	xml.alg key[:alg]
	xml.pubKey key[:pubKey]
      end
    end
    def make_ds_data(xml, ds)
      xml.dsData do
	xml.keyTag ds[:keyTag]
	xml.alg ds[:alg]
	xml.digestType ds[:digestType]
	xml.digest ds[:digest]
	make_key_data(xml, ds[:keyData]) if ds.key?(:keyData)
      end
    end
    def parse_key_data(xml)
      {
	:flags => xml.xpath("secDNS:flags", EPPClient::SCHEMAS_URL).text.to_i,
	:protocol => xml.xpath("secDNS:protocol", EPPClient::SCHEMAS_URL).text.to_i,
	:alg => xml.xpath("secDNS:alg", EPPClient::SCHEMAS_URL).text.to_i,
	:pubKey => xml.xpath("secDNS:pubKey", EPPClient::SCHEMAS_URL).text,
      }
    end
    def parse_ds_data(xml)
      ret = {
	:keyTag => xml.xpath("secDNS:keyTag", EPPClient::SCHEMAS_URL).text.to_i,
	:alg => xml.xpath("secDNS:alg", EPPClient::SCHEMAS_URL).text.to_i,
	:digestType => xml.xpath("secDNS:digestType", EPPClient::SCHEMAS_URL).text.to_i,
	:digest => xml.xpath("secDNS:digest", EPPClient::SCHEMAS_URL).text
      }
      if (keyData = xml.xpath('secDNS:keyData', EPPClient::SCHEMAS_URL)).size > 0
	ret[:keyData] = parse_key_data(keyData)
      end
      ret
    end

  end
end
