# $Abso$

class EPPClient
  module Session
    def login_xml
      command do |xml|
	xml.login do
	  xml.clID(@login)
	  xml.pw(@password)
	  xml.options do
	    xml.version(@version)
	    xml.lang(@lang)
	  end
	  xml.svcs do
	    services.each do |s|
	      xml.objURI(s)
	    end
	    unless extensions.empty?
	      xml.svcExtension do
		extensions.each do |e|
		  xml.extURI(e)
		end
	      end
	    end
	  end
	end
      end
    end

    def login
      response = send_request(login_xml)

    end

    def get_result(xml, range = 1000..1999)
      res = doc.xpath('/epp/response/result')
      code = res.attribute('code').value.to_i
      if range.include?(code)
	return true
      else
	raise EPPErrorResponse.new(:xml => xml, :code => code, :message => res.xpath('msg').text)
      end
    end
  end
end
