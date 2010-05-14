# $Abso$

module EPPClient::Poll
  def poll_req_xml #:nodoc:
    command do |xml|
      xml.poll(:op => :req)
    end
  end

  # sends a <epp:poll op="req"> command to the server.
  def poll_req
    response = send_request(poll_req_xml)

    get_result(:xml => response, :callback => :poll_req_process)
  end

  PARSERS = {}

  def poll_req_process(xml) #:nodoc:
    obj = xml.xpath('epp:resData', EPPClient::SCHEMAS_URL)
    ret = { :obj => obj.to_s }
    if (date = xml.xpath("epp:msgQ/epp:qDate", EPPClient::SCHEMAS_URL)).size > 0
      ret[:qDate] = DateTime.parse(date.text)
    end
    if (msg = xml.xpath("epp:msgQ/epp:msg", EPPClient::SCHEMAS_URL)).size > 0
      ret[:msg] = msg.text
    end
    PARSERS.each do |xpath,parser|
      if xml.xpath("epp:resData/#{xpath}", EPPClient::SCHEMAS_URL).size > 0
	ret[:obj] = case parser
		    when Symbol
		      send(parser, xml)
		    else
		      raise NotImplementedError
		    end
      end
    end
    ret
  end
end
