# $Abso$

class EPPClient
  module Session
    def hello
      send_request(command do |xml|
	xml.hello
      end)
    end

    def login_xml(new_pw = nil)
      command do |xml|
	xml.login do
	  xml.clID(@client_id)
	  xml.pw(@password)
	  xml.newPW(new_pw) unless new_pw.nil?
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
    private :login_xml

    def login(new_pw = nil)
      response = send_request(login_xml(new_pw))

      get_result(response)
    end

    def logout
      response = send_request(command do |xml|
	xml.logout
      end)

      get_result(response)
    end

    def get_result(args)
      xml = case args
	    when Hash
	      args.delete(:xml)
	    else
	      xml = args
	      args = {}
	      xml
	    end

      args[:range] ||= 1000..1999
	
      res = xml.xpath('epp:epp/epp:response/epp:result', SCHEMAS_URL)
      code = res.attribute('code').value.to_i
      if args[:range].include?(code)
	if args.key?(:callback)
	  case cb = args[:callback]
	  when Symbol
	    return send(cb, xml.xpath('epp:epp/epp:response', SCHEMAS_URL))
	  else
	    raise ArgumentError, "Invalid callback type"
	  end
	else
	  return xml
	end
      else
	raise EPPErrorResponse.new(:xml => xml, :code => code, :message => res.xpath('epp:msg', SCHEMAS_URL).text)
      end
    end
  end
end
