module EPPClient
  module Connection
    attr_reader :sent_frame, :recv_frame, :srv_version, :srv_lang, :srv_ns, :srv_ext

    # Establishes the connection to the server, if successful, will return the
    # greeting frame.
    def open_connection
      @tcpserver = TCPSocket.new(server, port)
      @socket = OpenSSL::SSL::SSLSocket.new(@tcpserver, @context)

      # Synchronously close the connection & socket
      @socket.sync_close

      # Connect
      @socket.connect

      # Get the initial greeting frame
      greeting_process(get_frame)
    end

    def greeting_process(xml) #:nodoc:
      @srv_version = xml.xpath('epp:epp/epp:greeting/epp:svcMenu/epp:version', EPPClient::SCHEMAS_URL).map {|n| n.text}
      @srv_lang = xml.xpath('epp:epp/epp:greeting/epp:svcMenu/epp:lang', EPPClient::SCHEMAS_URL).map {|n| n.text}
      @srv_ns = xml.xpath('epp:epp/epp:greeting/epp:svcMenu/epp:objURI', EPPClient::SCHEMAS_URL).map {|n| n.text}
      if (ext = xml.xpath('epp:epp/epp:greeting/epp:svcMenu/epp:svcExtension/epp:extURI', EPPClient::SCHEMAS_URL)).size > 0
        @srv_ext = ext.map {|n| n.text}
      end

      xml
    end

    # Gracefully close the connection
    def close_connection
      if defined?(@socket) && @socket.is_a?(OpenSSL::SSL::SSLSocket)
        @socket.close
        @socket = nil
      end

      if defined?(@tcpserver) && @tcpserver.is_a?(TCPSocket)
        @tcpserver.close
        @tcpserver = nil
      end

      return true if @tcpserver.nil? && @socket.nil?
    end

    # Sends a frame and returns the server's answer
    def send_request(xml)
      send_frame(xml)
      get_frame
    end

    # sends a frame
    def send_frame(xml)
      @sent_frame = xml
      @socket.write([xml.size + 4].pack("N") + xml)
      sent_frame_to_xml
    end

    # gets a frame from the socket and returns the parsed response.
    def get_frame
      size = @socket.read(4)
      if size.nil?
        if @socket.eof?
          raise SocketError, "Connection closed by remote server"
        else
          raise SocketError, "Error reading frame from remote server"
        end
      else
        size = size.unpack('N')[0]
        @recv_frame = @socket.read(size - 4)
        recv_frame_to_xml
      end
    end
  end
end
