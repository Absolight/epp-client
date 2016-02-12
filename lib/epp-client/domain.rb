module EPPClient
  module Domain
    EPPClient::Poll::PARSERS['domain:panData'] = :domain_pending_action_process
    EPPClient::Poll::PARSERS['domain:trnData'] = :domain_transfer_response

    def domain_check_xml(*domains) # :nodoc:
      command do |xml|
        xml.check do
          xml.check('xmlns' => EPPClient::SCHEMAS_URL['domain-1.0']) do
            domains.each do |dom|
              xml.name(dom)
            end
          end
        end
      end
    end

    # Check the availability of domains
    #
    # takes a list of domains as arguments
    #
    # returns an array of hashes containing three fields :
    # [<tt>:name</tt>] The domain name
    # [<tt>:avail</tt>] Wether the domain is available or not.
    # [<tt>:reason</tt>] The reason for non availability, if given.
    def domain_check(*domains)
      domains.flatten!
      response = send_request(domain_check_xml(*domains))

      get_result(:xml => response, :callback => :domain_check_process)
    end

    def domain_check_process(xml) # :nodoc:
      xml.xpath('epp:resData/domain:chkData/domain:cd', EPPClient::SCHEMAS_URL).map do |dom|
        ret = {
          :name => dom.xpath('domain:name', EPPClient::SCHEMAS_URL).text,
          :avail => dom.xpath('domain:name', EPPClient::SCHEMAS_URL).attr('avail').value == '1',
        }
        unless (reason = dom.xpath('domain:reason', EPPClient::SCHEMAS_URL).text).empty?
          ret[:reason] = reason
        end
        ret
      end
    end

    def domain_info_xml(args) # :nodoc:
      command do |xml|
        xml.info do
          xml.info('xmlns' => EPPClient::SCHEMAS_URL['domain-1.0']) do
            xml.name(args[:name])
            if args.key?(:authInfo)
              xml.authInfo do
                if args.key?(:roid)
                  xml.pw({ :roid => args[:roid] }, args[:authInfo])
                else
                  xml.pw(args[:authInfo])
                end
              end
            end
          end
        end
      end
    end

    # Returns the informations about a domain
    #
    # Takes either a unique argument, a string, representing the domain, or a
    # hash with : <tt>:name</tt> the domain name, and optionnaly
    # <tt>:authInfo</tt> the authentication information and possibly
    # <tt>:roid</tt> the contact the authInfo is about.
    #
    # Returned is a hash mapping as closely as possible the result expected
    # from the command as per Section
    # {3.1.2}[https://tools.ietf.org/html/rfc5731#section-3.1.2] of {RFC
    # 5731}[https://tools.ietf.org/html/rfc5731] :
    # [<tt>:name</tt>] The fully qualified name of the domain object.
    # [<tt>:roid</tt>]
    #    The Repository Object IDentifier assigned to the domain object when
    #    the object was created.
    # [<tt>:status</tt>]
    #    an optionnal array of elements that contain the current status
    #    descriptors associated with the domain.
    # [<tt>:registrant</tt>] one optionnal registrant nic handle.
    # [<tt>:contacts</tt>]
    #   an optionnal hash which keys are choosen between +admin+, +billing+ and
    #   +tech+ and which values are arrays of nic handles for the corresponding
    #   contact types.
    # [<tt>:ns</tt>]
    #   an optional array containing nameservers informations, which can either
    #   be an array of strings containing the the fully qualified name of a
    #   host, or an array of hashes containing the following keys :
    #   [<tt>:hostName</tt>] the fully qualified name of a host.
    #   [<tt>:hostAddrv4</tt>]
    #      an optionnal array of ipv4 addresses to be associated with the host.
    #   [<tt>:hostAddrv6</tt>]
    #      an optionnal array of ipv6 addresses to be associated with the host.
    # [<tt>:host</tt>]
    #    an optionnal array of fully qualified names of the subordinate host
    #    objects that exist under this superordinate domain object.
    # [<tt>:clID</tt>] the identifier of the sponsoring client.
    # [<tt>:crID</tt>]
    #   an optional identifier of the client that created the domain object.
    # [<tt>:crDate</tt>] an optional date and time of domain object creation.
    # [<tt>:exDate</tt>]
    #   the date and time identifying the end of the domain object's
    #   registration period.
    # [<tt>:upID</tt>]
    #   the identifier of the client that last updated the domain object.
    # [<tt>:upDate</tt>]
    #   the date and time of the most recent domain-object modification.
    # [<tt>:trDate</tt>]
    #   the date and time of the most recent successful domain-object transfer.
    # [<tt>:authInfo</tt>]
    #   authorization information associated with the domain object.
    def domain_info(args)
      args = { :name => args } if String === args
      response = send_request(domain_info_xml(args))

      get_result(:xml => response, :callback => :domain_info_process)
    end

    def domain_info_process(xml) # :nodoc:
      dom = xml.xpath('epp:resData/domain:infData', EPPClient::SCHEMAS_URL)
      ret = {
        :name => dom.xpath('domain:name', EPPClient::SCHEMAS_URL).text,
        :roid => dom.xpath('domain:roid', EPPClient::SCHEMAS_URL).text,
      }
      if (status = dom.xpath('domain:status', EPPClient::SCHEMAS_URL)).size > 0
        ret[:status] = status.map { |s| s.attr('s') }
      end
      if (registrant = dom.xpath('domain:registrant', EPPClient::SCHEMAS_URL)).size > 0
        ret[:registrant] = registrant.text
      end
      if (contact = dom.xpath('domain:contact', EPPClient::SCHEMAS_URL)).size > 0
        ret[:contacts] = contact.inject({}) do |a, c|
          s = c.attr('type').to_sym
          a[s] ||= []
          a[s] << c.text
          a
        end
      end
      if (ns = dom.xpath('domain:ns', EPPClient::SCHEMAS_URL)).size > 0
        if (hostObj = ns.xpath('domain:hostObj', EPPClient::SCHEMAS_URL)).size > 0
          ret[:ns] = hostObj.map { |h| h.text }
        elsif (hostAttr = ns.xpath('domain:hostAttr', EPPClient::SCHEMAS_URL)).size > 0
          ret[:ns] = hostAttr.map do |h|
            r = { :hostName => h.xpath('domain:hostName', EPPClient::SCHEMAS_URL).text }
            if (v4 = h.xpath('domain:hostAddr[@ip="v4"]', EPPClient::SCHEMAS_URL)).size > 0
              r[:hostAddrv4] = v4.map { |v| v.text }
            end
            if (v6 = h.xpath('domain:hostAddr[@ip="v6"]', EPPClient::SCHEMAS_URL)).size > 0
              r[:hostAddrv6] = v6.map { |v| v.text }
            end
            r
          end
        end
      end
      if (host = dom.xpath('domain:host', EPPClient::SCHEMAS_URL)).size > 0
        ret[:host] = host.map { |h| h.text }
      end
      %w(clID upID).each do |val|
        if (r = dom.xpath("domain:#{val}", EPPClient::SCHEMAS_URL)).size > 0
          ret[val.to_sym] = r.text
        end
      end
      %w(crDate exDate upDate trDate).each do |val|
        if (r = dom.xpath("domain:#{val}", EPPClient::SCHEMAS_URL)).size > 0
          ret[val.to_sym] = DateTime.parse(r.text)
        end
      end
      if (authInfo = dom.xpath('domain:authInfo', EPPClient::SCHEMAS_URL)).size > 0
        ret[:authInfo] = authInfo.xpath('domain:pw', EPPClient::SCHEMAS_URL).text
      end
      ret
    end

    def domain_nss_xml(xml, nss) #:nodoc:
      xml.ns do
        if nss.first.is_a?(Hash)
          nss.each do |ns|
            xml.hostAttr do
              xml.hostName ns[:hostName]
              if ns.key?(:hostAddrv4)
                ns[:hostAddrv4].each do |v4|
                  xml.hostAddr({ :ip => :v4 }, v4)
                end
              end
              if ns.key?(:hostAddrv6)
                ns[:hostAddrv6].each do |v6|
                  xml.hostAddr({ :ip => :v6 }, v6)
                end
              end
            end
          end
        else
          nss.each do |ns|
            xml.hostObj ns
          end
        end
      end
    end

    def domain_contacts_xml(xml, args) #:nodoc:
      args.each do |type, contacts|
        contacts.each do |c|
          xml.contact({ :type => type }, c)
        end
      end
    end

    def domain_create_xml(args) #:nodoc:
      command do |xml|
        xml.create do
          xml.create('xmlns' => EPPClient::SCHEMAS_URL['domain-1.0']) do
            xml.name args[:name]

            if args.key?(:period)
              xml.period({ :unit => args[:period][:unit] }, args[:period][:number])
            end

            domain_nss_xml(xml, args[:ns]) if args.key?(:ns)

            xml.registrant args[:registrant] if args.key?(:registrant)

            domain_contacts_xml(xml, args[:contacts]) if args.key?(:contacts)

            xml.authInfo do
              xml.pw args[:authInfo]
            end
          end
        end
      end
    end

    # Creates a domain
    #
    # Takes a hash as an argument, containing the following keys :
    #
    # [<tt>:name</tt>] the domain name
    # [<tt>:period</tt>]
    #   an optionnal hash containing the period for witch the domain is
    #   registered with the following keys :
    #   [<tt>:unit</tt>] the unit of time, either "m"onth or "y"ear.
    #   [<tt>:number</tt>] the number of unit of time.
    # [<tt>:ns</tt>]
    #   an optional array containing nameservers informations, which can either
    #   be an array of strings containing the nameserver's hostname, or an
    #   array of hashes containing the following keys :
    #   [<tt>:hostName</tt>] the hostname of the nameserver.
    #   [<tt>:hostAddrv4</tt>] an optionnal array of ipv4 addresses.
    #   [<tt>:hostAddrv6</tt>] an optionnal array of ipv6 addresses.
    # [<tt>:registrant</tt>] an optionnal registrant nic handle.
    # [<tt>:contacts</tt>]
    #   an optionnal hash which keys are choosen between +admin+, +billing+ and
    #   +tech+ and which values are arrays of nic handles for the corresponding
    #   contact types.
    # [<tt>:authInfo</tt>] the password associated with the domain.
    #
    # Returns a hash with the following keys :
    #
    # [<tt>:name</tt>] the fully qualified name of the domain object.
    # [<tt>:crDate</tt>] the date and time of domain object creation.
    # [<tt>:exDate</tt>]
    #   the date and time identifying the end of the domain object's
    #   registration period.
    def domain_create(args)
      response = send_request(domain_create_xml(args))

      get_result(:xml => response, :callback => :domain_create_process)
    end

    def domain_create_process(xml) #:nodoc:
      dom = xml.xpath('epp:resData/domain:creData', EPPClient::SCHEMAS_URL)
      ret = {
        :name => dom.xpath('domain:name', EPPClient::SCHEMAS_URL).text,
        :crDate => DateTime.parse(dom.xpath('domain:crDate', EPPClient::SCHEMAS_URL).text),
        :upDate => DateTime.parse(dom.xpath('domain:crDate', EPPClient::SCHEMAS_URL).text),
      }
      ret
    end

    def domain_delete_xml(domain) #:nodoc:
      command do |xml|
        xml.delete do
          xml.delete('xmlns' => EPPClient::SCHEMAS_URL['domain-1.0']) do
            xml.name domain
          end
        end
      end
    end

    # Deletes a domain
    #
    # Takes a single fully qualified domain name for argument.
    #
    # Returns true on success, or raises an exception.
    def domain_delete(domain)
      response = send_request(domain_delete_xml(domain))

      get_result(response)
    end

    def domain_update_xml(args) #:nodoc:
      command do |xml|
        xml.update do
          xml.update('xmlns' => EPPClient::SCHEMAS_URL['domain-1.0']) do
            xml.name args[:name]
            [:add, :rem].each do |ar|
              next unless args.key?(ar) && (args[ar].key?(:ns) || args[ar].key?(:contacts) || args[ar].key?(:status))
              xml.__send__(ar) do
                domain_nss_xml(xml, args[ar][:ns]) if args[ar].key?(:ns)
                if args[ar].key?(:contacts)
                  domain_contacts_xml(xml, args[ar][:contacts])
                end
                if args[ar].key?(:status)
                  args[ar][:status].each do |st, text|
                    if text.nil?
                      xml.status(:s => st)
                    else
                      xml.status({ :s => st }, text)
                    end
                  end
                end
              end
            end
            if args.key?(:chg) && (args[:chg].key?(:registrant) || args[:chg].key?(:authInfo))
              xml.chg do
                if args[:chg].key?(:registrant)
                  xml.registrant args[:chg][:registrant]
                end
                if args[:chg].key?(:authInfo)
                  xml.authInfo do
                    xml.pw args[:chg][:authInfo]
                  end
                end
              end
            end
          end
        end
      end
    end

    # Updates a domain
    #
    # Takes a hash with the name, and at least one of the following keys :
    # [<tt>:name</tt>]
    #   the fully qualified name of the domain object to be updated.
    # [<tt>:add</tt>/<tt>:rem</tt>]
    #   adds / removes the following data to/from the domain object :
    #   [<tt>:ns</tt>]
    #     an optional array containing nameservers informations, which can either
    #     be an array of strings containing the nameserver's hostname, or an
    #     array of hashes containing the following keys :
    #     [<tt>:hostName</tt>] the hostname of the nameserver.
    #     [<tt>:hostAddrv4</tt>] an optionnal array of ipv4 addresses.
    #     [<tt>:hostAddrv6</tt>] an optionnal array of ipv6 addresses.
    #   [<tt>:contacts</tt>]
    #     an optionnal hash which keys are choosen between +admin+, +billing+ and
    #     +tech+ and which values are arrays of nic handles for the corresponding
    #     contact types.
    #   [<tt>:status</tt>]
    #     an optional hash with status values to be applied to or removed from
    #     the object. When specifying a value to be removed, only the attribute
    #     value is significant; element text is not required to match a value
    #     for removal.
    # [<tt>:chg</tt>]
    #   changes the following in the domain object.
    #   [<tt>:registrant</tt>] an optionnal registrant nic handle.
    #   [<tt>:authInfo</tt>] an optional password associated with the domain.
    #
    # Returns true on success, or raises an exception.
    def domain_update(args)
      response = send_request(domain_update_xml(args))

      get_result(response)
    end

    def domain_pending_action_process(xml) #:nodoc:
      dom = xml.xpath('epp:resData/domain:panData', EPPClient::SCHEMAS_URL)
      ret = {
        :name => dom.xpath('domain:name', EPPClient::SCHEMAS_URL).text,
        :paResult => dom.xpath('domain:name', EPPClient::SCHEMAS_URL).attribute('paResult').value,
        :paTRID => get_trid(dom.xpath('domain:paTRID', EPPClient::SCHEMAS_URL)),
        :paDate => DateTime.parse(dom.xpath('domain:paDate', EPPClient::SCHEMAS_URL).text),
      }
      ret
    end

    def domain_transfer_response(xml) #:nodoc:
      dom = xml.xpath('epp:resData/domain:trnData', EPPClient::SCHEMAS_URL)
      ret = {
        :name => dom.xpath('domain:name', EPPClient::SCHEMAS_URL).text,
        :trStatus => dom.xpath('domain:trStatus', EPPClient::SCHEMAS_URL).text,
        :reID => dom.xpath('domain:reID', EPPClient::SCHEMAS_URL).text,
        :reDate => DateTime.parse(dom.xpath('domain:reDate', EPPClient::SCHEMAS_URL).text),
        :acID => dom.xpath('domain:acID', EPPClient::SCHEMAS_URL).text,
        :acDate => DateTime.parse(dom.xpath('domain:acDate', EPPClient::SCHEMAS_URL).text),
      }
      if (exDate = dom.xpath('domain:exDate', EPPClient::SCHEMAS_URL)).size > 0
        ret[:exDate] = DateTime.parse(exDate)
      end
      ret
    end

    def domain_transfer_xml(args) # :nodoc:
      command do |xml|
        xml.transfer('op' => args[:op]) do
          xml.transfer('xmlns' => EPPClient::SCHEMAS_URL['domain-1.0']) do
            xml.name(args[:name])
            if args.key?(:period)
              xml.period('unit' => args[:period][:unit]) do
                args[:period][:number]
              end
            end
            if args.key?(:authInfo)
              xml.authInfo do
                if args.key?(:roid)
                  xml.pw({ :roid => args[:roid] }, args[:authInfo])
                else
                  xml.pw(args[:authInfo])
                end
              end
            end
          end
        end
      end
    end

    # Transfers a domain
    #
    # Takes a hash with :
    #
    # [<tt>:name</tt>] The domain name
    # [<tt>:op</tt>] An operation that can either be "query" or "request".
    # [<tt>:authInfo</tt>]
    #   The authentication information and possibly <tt>:roid</tt> the contact
    #   the authInfo is about.  The <tt>:authInfo</tt> information is optional
    #   when the operation type is "query" and mandatory when it is "request".
    # [<tt>:period</tt>]
    #   An optionnal hash containing the period for witch the domain is
    #   registered with the following keys :
    #   [<tt>:unit</tt>] the unit of time, either "m"onth or "y"ear.
    #   [<tt>:number</tt>] the number of unit of time.
    #
    # Returned is a hash mapping as closely as possible the result expected
    # from the command as per Section
    # {3.1.3}[https://tools.ietf.org/html/rfc5731#section-3.1.3] and
    # {3.2.4}[https://tools.ietf.org/html/rfc5731#section-3.2.4] of {RFC
    # 5731}[https://tools.ietf.org/html/rfc5731] :
    # [<tt>:name</tt>] The fully qualified name of the domain object.
    # [<tt>:trStatus</tt>] The state of the most recent transfer request.
    # [<tt>:reID</tt>]
    #   The identifier of the client that requested the object transfer.
    # [<tt>:reDate</tt>] The date and time that the transfer was requested.
    # [<tt>:acID</tt>]
    #   The identifier of the client that SHOULD act upon a PENDING transfer
    #   request.  For all other status types, the value identifies the client
    #   that took the indicated action.
    # [<tt>:acDate</tt>]
    #   The date and time of a required or completed response.  For a PENDING
    #   request, the value identifies the date and time by which a response is
    #   required before an automated response action will be taken by the
    #   server.  For all other status types, the value identifies the date and
    #   time when the request was completed.
    #
    # [<tt>:exDate</tt>]
    #   Optionnaly, the end of the domain object's validity period if the
    #   <transfer> command caused or causes a change in the validity period.
    def domain_transfer(args)
      response = send_request(domain_transfer_xml(args))

      get_result(:xml => response, :callback => :domain_transfer_response)
    end
  end
end
