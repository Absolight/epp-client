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
    # [<tt>:client_id</tt>] the tag or username used with <tt><login></tt> requests.
    # [<tt>:password</tt>] the password used with <tt><login></tt> requests.
    # [<tt>:ssl_cert</tt>] the file containing the client certificate.
    # [<tt>:ssl_key</tt>] the file containing the key of the certificate.
    #
    # ==== Optional Attributes
    # [<tt>:test</tt>] sets the server to be the test server.
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

    # Extends the base contact info so that the specific smallregistry's
    # informations are processed, the additionnal informations are :
    #
    # one of :
    # [<tt>:org</tt>]
    #	indicating that the contact is an organisation with the following
    #	informations :
    #	[<tt>:companySerial</tt>]
    #	  the company's SIREN / RPPS / whatever serial number is required.
    # [<tt>:person</tt>]
    #   indicating that the contact is a human person with the following
    #   informations :
    #   [<tt>:birthDate</tt>] the person's birth date.
    #   [<tt>:birthPlace</tt>] the person's birth place.
    def contact_info(xml)
      super # placeholder so that I can add some doc
    end 

    def contact_info_process(xml) #:nodoc:
      ret = super
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

    # Extends the base contact create so that the specific smallregistry's
    # information are sent, the additionnal informations are :
    #
    # one of :
    # [<tt>:org</tt>]
    #	indicating that the contact is an organisation with the following
    #	informations :
    #	[<tt>:companySerial</tt>]
    #	  the company's SIREN / RPPS / whatever serial number is required.
    # [<tt>:person</tt>]
    #   indicating that the contact is a human person with the following
    #   informations :
    #   [<tt>:birthDate</tt>] the person's birth date.
    #   [<tt>:birthPlace</tt>] the person's birth place.
    def contact_create(contact)
      super # placeholder so that I can add some doc
    end

    def contact_create_xml(contact) #:nodoc:
      ret = super

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
  end
end
