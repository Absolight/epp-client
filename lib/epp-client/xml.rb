module EPPClient
  module XML
    attr_reader :sent_xml, :recv_xml, :msgQ_count, :msgQ_id, :trID

    # Parses a frame and returns a Nokogiri::XML::Document.
    def parse_xml(string) #:doc:
      Nokogiri::XML::Document.parse(string) do |opts|
        opts.options = 0
        opts.noblanks
      end
    end
    private :parse_xml

    def recv_frame_to_xml #:nodoc:
      @recv_xml = parse_xml(@recv_frame)
      puts @recv_xml.to_s.gsub(/^/, '<< ') if debug
      @recv_xml
    end

    def sent_frame_to_xml #:nodoc:
      @send_xml = parse_xml(@sent_frame)
      puts @send_xml.to_s.gsub(/^/, '>> ') if debug
      @send_xml
    end

    def raw_builder(opts = {}) #:nodoc:
      xml = Builder::XmlMarkup.new(opts)
      yield xml
    end

    # creates a Builder::XmlMarkup object, mostly only used by +command+
    def builder(opts = {})
      raw_builder(opts) do |xml|
        xml.instruct! :xml, :version => '1.0', :encoding => 'UTF-8'
        xml.epp('xmlns' => EPPClient::SCHEMAS_URL['epp'], 'xmlns:epp' => EPPClient::SCHEMAS_URL['epp']) do
          yield xml
        end
      end
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

      if (mq = xml.xpath('epp:epp/epp:response/epp:msgQ', EPPClient::SCHEMAS_URL)).size > 0
        @msgQ_count = mq.attribute('count').value.to_i
        @msgQ_id = mq.attribute('id').value
        puts "DEBUG: MSGQ : count=#{@msgQ_count}, id=#{@msgQ_id}\n" if debug
      else
        @msgQ_count = 0
        @msgQ_id = nil
      end

      if (trID = xml.xpath('epp:epp/epp:response/epp:trID', EPPClient::SCHEMAS_URL)).size > 0
        @trID = get_trid(trID)
      end

      res = xml.xpath('epp:epp/epp:response/epp:result', EPPClient::SCHEMAS_URL)
      code = res.attribute('code').value.to_i
      if args[:range].include?(code)
        if args.key?(:callback)
          case cb = args[:callback]
          when Symbol
            return send(cb, xml.xpath('epp:epp/epp:response', EPPClient::SCHEMAS_URL))
          else
            fail ArgumentError, 'Invalid callback type'
          end
        else
          return true
        end
      else
        fail EPPClient::EPPErrorResponse.new(:xml => xml, :code => code, :message => res.xpath('epp:msg', EPPClient::SCHEMAS_URL).text)
      end
    end

    def get_trid(xml)
      {
        :clTRID => xml.xpath('epp:clTRID', EPPClient::SCHEMAS_URL).text,
        :svTRID => xml.xpath('epp:svTRID', EPPClient::SCHEMAS_URL).text,
      }
    end

    # Creates the xml for the command.
    #
    # You can either pass a block to it, in that case, it's the command body,
    # or a series of procs, the first one being the commands, the other ones
    # being the extensions.
    #
    #   command do |xml|
    #       xml.logout
    #   end
    #
    # or
    #
    #   command(lambda do |xml|
    #       xml.logout
    #     end, lambda do |xml|
    #       xml.extension
    #     end)
    def command(*args, &_block)
      builder do |xml|
        xml.command do
          if block_given?
            yield xml
          else
            command = args.shift
            command.call(xml)
            args.each do |ext|
              xml.extension do
                ext.call(xml)
              end
            end
          end
          xml.clTRID(clTRID)
        end
      end
    end

    # Wraps the content in an epp:extension.
    def extension
      raw_builder do |xml|
        xml.extension do
          yield(xml)
        end
      end
    end

    # Insert xml2 in xml1 before pattern
    def insert_extension(xml1, xml2, pattern = /<clTRID>/)
      xml1.sub(pattern, "#{xml2}\\&")
    end
  end
end
