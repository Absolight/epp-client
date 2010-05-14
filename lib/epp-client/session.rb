# $Abso$

module EPPClient::Session

  # Sends an hello epp command.
  def hello
    send_request(command do |xml|
      xml.hello
    end)
  end

  def login_xml(new_pw = nil) #:nodoc:
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

  # Perform the login command on the server. Takes an optionnal argument, the
  # new password for the account.
  def login(new_pw = nil)
    response = send_request(login_xml(new_pw))

    get_result(response)
  end

  # Performs the logout command, after it, the server terminates the
  # connection.
  def logout
    response = send_request(command do |xml|
      xml.logout
    end)

    get_result(response)
  end

  # Takes a xml response and checks that the result is in the right range of
  # results, that is, between 1000 and 1999, which are results meaning all
  # went well.
  #
  # In case all went well, it either calls the callback if given, or returns
  # true.
  #
  # In case there was a problem, an EPPErrorResponse exception is raised.
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

    res = xml.xpath('epp:epp/epp:response/epp:result', EPPClient::SCHEMAS_URL)
    code = res.attribute('code').value.to_i
    if args[:range].include?(code)
      if args.key?(:callback)
	case cb = args[:callback]
	when Symbol
	  return send(cb, xml.xpath('epp:epp/epp:response', EPPClient::SCHEMAS_URL))
	else
	  raise ArgumentError, "Invalid callback type"
	end
      else
	return true
      end
    else
      raise EPPErrorResponse.new(:xml => xml, :code => code, :message => res.xpath('epp:msg', EPPClient::SCHEMAS_URL).text)
    end
  end
end
