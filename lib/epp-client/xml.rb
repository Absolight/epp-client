# $Abso$

class EPPClient
  module XML

    attr_reader :sent_xml, :recv_xml

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
      puts @recv_xml.to_s.gsub(/^/, '<< ') if $DEBUG
      return @recv_xml
    end

    def sent_frame_to_xml #:nodoc:
      @send_xml = parse_xml(@sent_frame)
      puts @send_xml.to_s.gsub(/^/, '>> ') if $DEBUG
      return @send_xml
    end

    def raw_builder(opts = {}) #:nodoc:
      xml = Builder::XmlMarkup.new(opts)
      yield xml
    end

    # creates a Builder::XmlMarkup object, mostly only used by +command+
    def builder(opts = {})
      raw_builder(opts) do |xml|
	xml.instruct! :xml, :version =>"1.0", :encoding => "UTF-8"
	xml.epp('xmlns' => SCHEMAS_URL['epp'], 'xmlns:epp' => SCHEMAS_URL['epp']) do
	  yield xml
	end
      end
    end

    # Creates the xml for the command.
    #
    # You can either pass a block to it, in that case, it's the command body,
    # or a series of procs, the first one being the commands, the other ones
    # being the extensions.
    #
    #   command do |xml|
    #  	  xml.logout
    #   end
    #
    # or
    #
    #   command(lambda do |xml|
    #	    xml.logout
    #	  end, lambda do |xml|
    #	    xml.extension
    #	  end)
    def command(*args, &block)
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
