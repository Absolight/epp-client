# $Abso$

class EPPClient
  module XML
    # Parses a frame and returns a Nokogiri::XML::Document.
    def parse_response(frame)
      Nokogiri::XML::Document.parse(frame) do |opts|
	opts.options = 0
	opts.noblanks
      end
    end

    # creates a Builder::XmlMarkup object, mostly only used by +command+
    def builder(opts = {})
      opts = {:indent => 2}.merge(opts)
      xml = Builder::XmlMarkup(opts)
      xml.instruct! :xml, :version =>"1.0", :encoding => "UTF-8"
      xml.epp('xmlns' => SCHEMAS_URL['epp']) do
	yield xml
      end
    end

    # Creates the xml for the command.
    #
    # You can either pass a block to it, in that case, it's the command body,
    # or a series of procs, the first one being the commands, the other ones
    # being the extensions.
    #
    # command do |xml|
    #	xml.logout
    # end
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
	  xml.clTRID(@clTRID)
	end
      end
    end
  end
end
