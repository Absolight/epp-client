module EPPClient
  # RFC3915[http://tools.ietf.org/html/rfc3915]
  #
  # Domain Registry Grace Period Mapping for the
  # Extensible Provisioning Protocol (EPP)
  #
  # Has to be included after the initialize, domain_info and domain_update
  # definitions.
  module RGP
    def initialize(args) #:nodoc:
      super
      @extensions << EPPClient::SCHEMAS_URL['rgp']
    end

    def domain_info_process(xml) #:nodoc:
      ret = super(xml)
      if (rgp_status = xml.xpath('epp:extension/rgp:infData/rgp:rgpStatus', EPPClient::SCHEMAS_URL)).size > 0
        ret[:rgpStatus] = rgp_status.map {|s| s.attr('s')}
      end
      ret
    end

    def domain_restore_xml(args) #:nodoc:
      command(lambda do |xml|
        xml.update do
          xml.update('xmlns' => EPPClient::SCHEMAS_URL['domain-1.0']) do
            xml.name args[:name]
          end
        end
      end, lambda do |xml|
        xml.update('xmlns' => EPPClient::SCHEMAS_URL['rgp-1.0']) do
          if args.key?(:report)
            xml.restore(:op => 'report') do
              [:preData, :postData, :delTime, :resTime, :resReason].each do |v|
                xml.__send__(v, args[:report][v])
              end
              args[:report][:statements].each do |s|
                xml.statement s
              end
              xml.other args[:report][:other] if args[:report].key?(:other)
            end
          else
            xml.restore(:op => 'request')
          end
        end
      end)
    end

    # Restores a domain.
    #
    # takes a hash as arguments, with the following keys :
    # [<tt>:name</tt>]
    #   the fully qualified name of the domain object to be updated.
    # [<tt>:report</tt>]
    #   the optional report with the following fields :
    #   [<tt>:preData</tt>]
    #     a copy of the registration data that existed for the domain name prior
    #     to the domain name being deleted.
    #   [<tt>:postData</tt>]
    #     a copy of the registration data that exists for the domain name at the
    #     time the restore report is submitted.
    #   [<tt>:delTime</tt>]
    #     the date and time when the domain name delete request was sent to the
    #     server.
    #   [<tt>:resTime</tt>]
    #     the date and time when the original <rgp:restore> command was sent to
    #     the server.
    #   [<tt>:resReason</tt>]
    #     a brief explanation of the reason for restoring the domain name.
    #   [<tt>:statements</tt>]
    #     an array of two statements :
    #     1. a text statement that the client has not restored the domain name in
    #        order to assume the rights to use or sell the domain name for itself
    #        or for any third party.  Supporting information related to this
    #        statement MAY be supplied in the <tt>:other</tt> element described
    #        below.
    #     2. a text statement that the information in the restore report is
    #        factual to the best of the client's knowledge.
    #   [<tt>:other</tt>]
    #     an optional element that contains any information needed to support the
    #     statements provided by the client.
    #
    # Returns an array of rgpStatus.
    def domain_restore(args)
      response = send_request(domain_restore_xml(args))

      get_result(:xml => response, :callback => :domain_restore_process)
    end

    def domain_restore_process(xml) #:nodoc:
      xml.xpath('epp:extension/rgp:upData/rgp:rgpStatus', EPPClient::SCHEMAS_URL).map {|s| s.attr('s')}
    end
  end
end
