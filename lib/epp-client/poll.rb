module EPPClient
  # This implements the poll EPP commands.
  module Poll
    def poll_req_xml #:nodoc:
      command do |xml|
        xml.poll(:op => :req)
      end
    end

    # sends a <tt><epp:poll op="req"></tt> command to the server.
    #
    # if there is a message in the queue, returns a hash with the following keys :
    # [<tt>:qDate</tt>] the date and time that the message was enqueued.
    # [<tt>:msg</tt>, <tt>:msg_xml</tt>]
    #   a human readble message, the <tt>:msg</tt> version has all the possible
    #   xml stripped, whereas the <tt>:msg_xml</tt> contains the original
    #   message.
    # [<tt>:obj</tt>, <tt>:obj_xml</tt>]
    #   contains a possible <tt><epp:resData></tt> object, the original one in
    #   <tt>:obj_xml</tt>, and if a parser is available, the parsed one in
    #   <tt>:obj</tt>.
    def poll_req
      response = send_request(poll_req_xml)

      get_result(:xml => response, :callback => :poll_req_process)
    end

    PARSERS = {}

    def poll_req_process(xml) #:nodoc:
      ret = {}
      if (date = xml.xpath('epp:msgQ/epp:qDate', EPPClient::SCHEMAS_URL)).size > 0
        ret[:qDate] = DateTime.parse(date.text)
      end
      if (msg = xml.xpath('epp:msgQ/epp:msg', EPPClient::SCHEMAS_URL)).size > 0
        ret[:msg] = msg.text
        ret[:msg_xml] = msg.to_s
      end
      if (obj = xml.xpath('epp:resData', EPPClient::SCHEMAS_URL)).size > 0 ||
         (obj = xml.xpath('epp:extension', EPPClient::SCHEMAS_URL)).size > 0
        ret[:obj_xml] = obj.to_s
        PARSERS.each do |xpath, parser|
          next unless obj.xpath(xpath, EPPClient::SCHEMAS_URL).size > 0
          ret[:obj] = case parser
                      when Symbol
                        send(parser, xml)
                      else
                        fail NotImplementedError
                      end
        end
      end
      ret
    end

    def poll_ack_xml(mid) #:nodoc:
      command do |xml|
        xml.poll(:op => :ack, :msgID => mid)
      end
    end

    # sends a <tt><epp:poll op="ack" msgID="<mid>"></tt> command to the server.
    # Most of the time, you should not pass any argument, as it will "do the
    # right thing".
    def poll_ack(mid = @msgQ_id)
      response = send_request(poll_ack_xml(mid))

      get_result(response)
    end
  end
end
