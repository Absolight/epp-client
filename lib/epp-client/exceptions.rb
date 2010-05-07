# $Abso$

class EPPClient
  class EPPErrorResponse < StandardError
    attr_accessor :response_xml, :response_code, :message

    def initialize(attrs = {})
      @response_xml = attrs[:xml]
      @response_code = attrs[:code]
      @message = attrs[:message]
    end

    def to_s #:nodoc:
      "#{@message} (code #{@response_code})"
    end

    def inspect #:nodoc:
      "#<#{self.class}: code: #{@response_code}, message: #{@message.inspect}, xml: #{@response_xml}>"
    end
  end
end
