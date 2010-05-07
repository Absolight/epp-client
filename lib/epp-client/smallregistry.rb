# $Abso$

require 'epp-client'

class EPPClient
  class SmallRegistry < EPPClient
    HG_KEYWORD << %q$Abso$

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
    # https://www.smallregistry.net/faqs/quelles-sont-les-specificites-du-serveur-epp
    #
    # ==== Required Attributes
    #
    # * <tt>:client_id</tt> - The tag or username used with <tt><login></tt> requests.
    # * <tt>:password</tt> - The password used with <tt><login></tt> requests.
    # * <tt>:ssl_cert</tt> - The file containing the client certificate.
    # * <tt>:ssl_key</tt> - The file containing the key of the certificate.
    #
    # ==== Optional Attributes
    # * <tt>:test</tt> - sets the server to be the test server.
    #
    # See EPPClient for other attributes.
    def initialize(attrs)
      unless attrs.key?(:client_id) && attrs.key?(:password) && attrs.key?(:ssl_cert) && attrs.key?(:ssl_key)
	raise ArgumentError, "client_id, password, ssl_cert and ssl_key are required"
      end
      if attrs.delete(:test) == true
	attrs[:server] ||= 'epp.test.smallregistry.net'
	attrs[:port] ||= 2700
      else
	attrs[:server] ||= 'epp.smallregistry.net'
	attrs[:port] ||= 700
      end
      super(attrs)
      @extensions << SCHEMAS_URL['sr']
    end

    def contact_info_process_with_smallregistry(xml) #:nodoc:
      ret = contact_info_process_without_smallregistry(xml)
      if (contact = xml.xpath('epp:extension/sr:ext/sr:infData/sr:contact', SCHEMAS_URL)).size > 0
	if (person = contact.xpath('sr:person', SCHEMAS_URL)).size > 0
	  ret[:person] = {
	    :birthDate => Date.parse(person.xpath('sr:birthDate', SCHEMAS_URL).text),
	    :birthPlace => person.xpath('sr:birthPlace', SCHEMAS_URL).text,
	  }
	end
	if (org = contact.xpath('sr:org', SCHEMAS_URL)).size > 0
	  ret[:org] = { :companySerial => org.xpath('sr:companySerial', SCHEMAS_URL).text }
	end
      end
      ret
    end
    alias_method :contact_info_process_without_smallregistry, :contact_info_process
    alias_method :contact_info_process, :contact_info_process_with_smallregistry

    def contact_create_xml_with_smallregistry(contact) #:nodoc:
      ret = contact_create_xml_without_smallregistry(contact)

      ext = extension do |xml|
	xml.ext( :xmlns => SCHEMAS_URL['sr']) do
	  xml.create do
	    xml.contact do
	      if contact.key?(:org)
		xml.org do
		  xml.companySerial(contact[:org][:companySerial])
		end
	      elsif contact.key?(:person)
		xml.person do
		  xml.birthDate(contact[:person][:birthDate])
		  xml.birthPlace(contact[:person][:birthPlace])
		end
	      end
	    end
	  end
	end
      end

      insert_extension(ret, ext)
    end
    alias_method :contact_create_xml_without_smallregistry, :contact_create_xml
    alias_method :contact_create_xml, :contact_create_xml_with_smallregistry
  end
end
