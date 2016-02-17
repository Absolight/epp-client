require 'epp-client/base'
require 'epp-client/rgp'
require 'epp-client/secdns'

module EPPClient
  # This handles the AFNIC specificities.
  #
  # See http://www.afnic.fr/doc/interface/epp
  class AFNIC < Base
    SCHEMAS_AFNIC = %w(
      frnic-1.4
    ).freeze

    EPPClient::SCHEMAS_URL.merge!(SCHEMAS_AFNIC.inject({}) do |a, s|
      a[s.sub(/-1\.4$/, '')] = "http://www.afnic.fr/xml/epp/#{s}" if s =~ /-1\.4$/
      a[s] = "http://www.afnic.fr/xml/epp/#{s}"
      a
    end)

    # Sets the default for AFNIC, that is, server and port, according to
    # AFNIC's documentation.
    # http://www.afnic.fr/doc/interface/epp
    #
    # ==== Optional Attributes
    # [<tt>:test</tt>] sets the server to be the test server.
    def initialize(args)
      args[:server] ||= if args.delete(:test) == true
                          'epp.sandbox.nic.fr'
                        else
                          'epp.nic.fr'
                        end
      @services = EPPClient::SCHEMAS_URL.values_at('domain', 'contact')
      args[:port] ||= 700
      super(args)
      @extensions << EPPClient::SCHEMAS_URL['frnic']
    end

    # Extends the EPPClient::Domain#domain_check so that the specific AFNIC
    # check informations are processed, the additionnal informations are :
    #
    # [<tt>:reserved</tt>] the domain is a reserved name.
    # [<tt>:rsvReason</tt>] the optional reason why the domain is reserved.
    # [<tt>:forbidden</tt>] the domain is a forbidden name.
    # [<tt>:fbdReason</tt>] the optional reason why the domain is forbidden.
    def domain_check(*domains)
      super # placeholder so that I can add some doc
    end

    def domain_check_process(xml) # :nodoc:
      ret = super
      xml.xpath('epp:extension/frnic:ext/frnic:resData/frnic:chkData/frnic:domain/frnic:cd', EPPClient::SCHEMAS_URL).each do |dom|
        name = dom.xpath('frnic:name', EPPClient::SCHEMAS_URL)
        hash = ret.find { |d| d[:name] == name.text }
        hash[:reserved] = name.attr('reserved').value == '1'
        unless (reason = dom.xpath('frnic:rsvReason', EPPClient::SCHEMAS_URL).text).empty?
          hash[:rsvReason] = reason
        end
        hash[:forbidden] = name.attr('forbidden').value == '1'
        unless (reason = dom.xpath('frnic:fbdReason', EPPClient::SCHEMAS_URL).text).empty?
          hash[:fbdReason] = reason
        end
      end
      ret
    end

    # Extends the EPPClient::Domain#domain_info so that the specific AFNIC
    # <tt>:status</tt> can be added.
    def domain_info(domain)
      super # placeholder so that I can add some doc
    end

    def domain_info_process(xml) #:nodoc:
      ret = super
      if (frnic_status = xml.xpath('epp:extension/frnic:ext/frnic:resData/frnic:infData/frnic:domain/frnic:status', EPPClient::SCHEMAS_URL)).size > 0
        ret[:status] ||= [] # The status is optional, there may be none at this point.
        ret[:status] += frnic_status.map { |s| s.attr('s') }
      end
      ret
    end

    # parse legalEntityInfos content.
    def legalEntityInfos(leI) #:nodoc:
      ret = {}
      ret[:legalStatus] = leI.xpath('frnic:legalStatus', EPPClient::SCHEMAS_URL).attr('s').value
      if (r = leI.xpath('frnic:idStatus', EPPClient::SCHEMAS_URL)).size > 0
        ret[:idStatus] = { :value => r.text }
        ret[:idStatus][:when] = r.attr('when').value if r.attr('when')
        ret[:idStatus][:source] = r.attr('source').value if r.attr('source')
      end
      %w(siren VAT trademark DUNS local).each do |val|
        if (r = leI.xpath("frnic:#{val}", EPPClient::SCHEMAS_URL)).size > 0
          ret[val.to_sym] = r.text
        end
      end
      if (asso = leI.xpath('frnic:asso', EPPClient::SCHEMAS_URL)).size > 0
        ret[:asso] = {}
        if (r = asso.xpath('frnic:waldec', EPPClient::SCHEMAS_URL)).size > 0
          ret[:asso][:waldec] = r.text
        else
          if (decl = asso.xpath('frnic:decl', EPPClient::SCHEMAS_URL)).size > 0
            ret[:asso][:decl] = Date.parse(decl.text)
          end
          publ = asso.xpath('frnic:publ', EPPClient::SCHEMAS_URL)
          ret[:asso][:publ] = {
            :date => Date.parse(publ.text),
            :page => publ.attr('page').value,
          }
          if (announce = publ.attr('announce')) && announce.value != '0'
            ret[:asso][:publ][:announce] = announce.value
          end
        end
      end
      ret
    end
    private :legalEntityInfos

    # Extends the EPPClient::Contact#contact_info so that the specific AFNIC
    # check informations are processed, the additionnal informations are :
    #
    # either :
    # [<tt>:legalEntityInfos</tt>]
    #   indicating that the contact is an organisation with the following
    #   informations :
    #   [<tt>:legalStatus</tt>]
    #     should be either +company+, +association+ or +other+.
    #   [<tt>:idStatus</tt>]
    #     indicates the identification process status. Has optional
    #     <tt>:when</tt> and <tt>:source</tt> attributes.
    #   [<tt>:siren</tt>] contains the SIREN number of the organisation.
    #   [<tt>:VAT</tt>]
    #     is optional and contains the VAT number of the organisation.
    #   [<tt>:trademark</tt>]
    #     is optional and contains the trademark number of the organisation.
    #   [<tt>:DUNS</tt>]
    #     is optional and contains the Data Universal Numbering System number of
    #     the organisation.
    #   [<tt>:local</tt>]
    #     is optional and contains an identifier local to the eligible country.
    #   [<tt>:asso</tt>]
    #     indicates the organisation is an association and contains either a
    #     +waldec+ or a +decl+ and a +publ+ :
    #     [<tt>:waldec</tt>] contains the waldec id of the association.
    #     [<tt>:decl</tt>]
    #       optionally indicate the date of the association was declared at the
    #       prefecture.
    #     [<tt>:publ</tt>]
    #       contains informations regarding the publication in the "Journal
    #       Officiel" :
    #       [<tt>:date</tt>] the date of publication.
    #       [<tt>:page</tt>] the page the announce is on.
    #       [<tt>:announce</tt>] the announce number on the page (optional).
    # [<tt>:individualInfos</tt>]
    #   indicating that the contact is a person with the following
    #   informations :
    #   [<tt>:idStatus</tt>]
    #     indicates the identification process status. Has optional
    #     <tt>:when</tt> and <tt>:source</tt> attributes.
    #   [<tt>:birthDate</tt>] the date of birth of the contact.
    #   [<tt>:birthCity</tt>] the city of birth of the contact.
    #   [<tt>:birthPc</tt>] the postal code of the city of birth.
    #   [<tt>:birthCc</tt>] the country code of the place of birth.
    #
    # Additionnaly, when the contact is a person, there can be the following
    # informations :
    # [<tt>:firstName</tt>]
    #   the first name of the person. (The last name being stored in the +name+
    #   field in the +postalInfo+.)
    # [<tt>:list</tt>]
    #   with the value of +restrictedPublication+ mean that the element
    #   diffusion should be restricted.
    #
    # Optionnaly, there can be :
    # [<tt>:obsoleted</tt>]
    #   the contact info is obsolete since/from the optional date <tt>:when</tt>.
    # [<tt>:reachable</tt>]
    #   the contact is reachable through the optional <tt>:media</tt> since/from
    #   the optional date <tt>:when</tt>. The info having been specified by the
    #   <tt>:source</tt>.
    def contact_info(contact)
      super # placeholder so that I can add some doc
    end

    def contact_info_process(xml) #:nodoc:
      ret = super
      if (contact = xml.xpath('epp:extension/frnic:ext/frnic:resData/frnic:infData/frnic:contact', EPPClient::SCHEMAS_URL)).size > 0
        if (list = contact.xpath('frnic:list', EPPClient::SCHEMAS_URL)).size > 0
          ret[:list] = list.map(&:text)
        end
        if (firstName = contact.xpath('frnic:firstName', EPPClient::SCHEMAS_URL)).size > 0
          ret[:firstName] = firstName.text
        end
        if (iI = contact.xpath('frnic:individualInfos', EPPClient::SCHEMAS_URL)).size > 0
          ret[:individualInfos] = {}
          ret[:individualInfos][:birthDate] = Date.parse(iI.xpath('frnic:birthDate', EPPClient::SCHEMAS_URL).text)
          if (r = iI.xpath('frnic:idStatus', EPPClient::SCHEMAS_URL)).size > 0
            ret[:individualInfos][:idStatus] = { :value => r.text }
            ret[:individualInfos][:idStatus][:when] = r.attr('when').value if r.attr('when')
            ret[:individualInfos][:idStatus][:source] = r.attr('source').value if r.attr('source')
          end
          %w(birthCity birthPc birthCc).each do |val|
            if (r = iI.xpath("frnic:#{val}", EPPClient::SCHEMAS_URL)).size > 0
              ret[:individualInfos][val.to_sym] = r.text
            end
          end
        end
        if (leI = contact.xpath('frnic:legalEntityInfos', EPPClient::SCHEMAS_URL)).size > 0
          ret[:legalEntityInfos] = legalEntityInfos(leI)
        end
        if (obsoleted = contact.xpath('frnic:obsoleted', EPPClient::SCHEMAS_URL)).size > 0
          if obsoleted.text != '0'
            ret[:obsoleted] = {}
            if (v_when = obsoleted.attr('when'))
              ret[:obsoleted][:when] = DateTime.parse(v_when.value)
            end
          end
        end
        if (reachable = contact.xpath('frnic:reachable', EPPClient::SCHEMAS_URL)).size > 0
          if reachable.text != '0'
            ret[:reachable] = {}
            if (v_when = reachable.attr('when'))
              ret[:reachable][:when] = DateTime.parse(v_when.value)
            end
            if (media = reachable.attr('media'))
              ret[:reachable][:media] = media.value
            end
            if (source = reachable.attr('source'))
              ret[:reachable][:source] = source.value
            end
          end
        end
      end
      ret
    end

    def contact_create_xml(contact) #:nodoc:
      ret = super

      ext = extension do |xml|
        xml.ext(:xmlns => EPPClient::SCHEMAS_URL['frnic']) do
          xml.create do
            xml.contact do
              if contact.key?(:legalEntityInfos)
                lEI = contact[:legalEntityInfos]
                xml.legalEntityInfos do
                  xml.idStatus(lEI[:idStatus]) if lEI.key?(:idStatus)
                  xml.legalStatus(:s => lEI[:legalStatus])
                  [:siren, :VAT, :trademark, :DUNS, :local].each do |val|
                    xml.__send__(val, lEI[val]) if lEI.key?(val)
                  end
                  if lEI.key?(:asso)
                    asso = lEI[:asso]
                    xml.asso do
                      if asso.key?(:waldec)
                        xml.waldec(asso[:waldec])
                      else
                        xml.decl(asso[:decl]) if asso.key?(:decl)
                        attrs = { :page => asso[:publ][:page] }
                        attrs[:announce] = asso[:publ][:announce] if asso[:publ].key?(:announce)
                        xml.publ(attrs, asso[:publ][:date])
                      end
                    end
                  end
                end
              else
                xml.list(contact[:list]) if contact.key?(:list)
                if contact.key?(:individualInfos)
                  iI = contact[:individualInfos]
                  xml.individualInfos do
                    xml.idStatus(iI[:idStatus]) if iI.key?(:idStatus)
                    xml.birthDate(iI[:birthDate])
                    xml.birthCity(iI[:birthCity]) if iI.key?(:birthCity)
                    xml.birthPc(iI[:birthPc]) if iI.key?(:birthPc)
                    xml.birthCc(iI[:birthCc])
                  end
                end
                xml.firstName(contact[:firstName]) if contact.key?(:firstName)
              end
              if contact.key?(:reachable)
                reachable = contact[:reachable]

                fail ArgumentError, 'reachable has to be a Hash' unless reachable.is_a?(Hash)

                xml.reachable(reachable, 1)
              end
            end
          end
        end
      end

      insert_extension(ret, ext)
    end

    # Extends the EPPClient::Contact#contact_create so that the specific AFNIC
    # create informations can be sent, the additionnal informations are :
    #
    # either :
    # [<tt>:legalEntityInfos</tt>]
    #   indicating that the contact is an organisation with the following
    #   informations :
    #   [<tt>:idStatus</tt>]
    #     indicates the identification process status.
    #   [<tt>:legalStatus</tt>]
    #     should be either +company+, +association+ or +other+.
    #   [<tt>:siren</tt>] contains the SIREN number of the organisation.
    #   [<tt>:VAT</tt>]
    #     is optional and contains the VAT number of the organisation.
    #   [<tt>:trademark</tt>]
    #     is optional and contains the trademark number of the organisation.
    #   [<tt>:DUNS</tt>]
    #     is optional and contains the Data Universal Numbering System number of
    #     the organisation.
    #   [<tt>:local</tt>]
    #     is optional and contains an identifier local to the eligible country.
    #   [<tt>:asso</tt>]
    #     indicates the organisation is an association and contains either a
    #     +waldec+ or a +decl+ and a +publ+ :
    #     [<tt>:waldec</tt>] contains the waldec id of the association.
    #     [<tt>:decl</tt>]
    #       optionally indicate the date of the association was declared at the
    #       prefecture.
    #     [<tt>:publ</tt>]
    #       contains informations regarding the publication in the "Journal
    #       Officiel" :
    #       [<tt>:date</tt>] the date of publication.
    #       [<tt>:page</tt>] the page the announce is on.
    #       [<tt>:announce</tt>] the announce number on the page (optional).
    # [<tt>:individualInfos</tt>]
    #   indicating that the contact is a person with the following
    #   informations :
    #   [<tt>:idStatus</tt>]
    #     indicates the identification process status.
    #   [<tt>:birthDate</tt>] the date of birth of the contact.
    #   [<tt>:birthCity</tt>] the city of birth of the contact.
    #   [<tt>:birthPc</tt>] the postal code of the city of birth.
    #   [<tt>:birthCc</tt>] the country code of the place of birth.
    #
    # Additionnaly, when the contact is a person, there can be the following
    # informations :
    # [<tt>:firstName</tt>]
    #   the first name of the person. (The last name being stored in the +name+
    #   field in the +postalInfo+.)
    # [<tt>:list</tt>]
    #   with the value of +restrictedPublication+ mean that the element
    #   diffusion should be restricted.
    #
    # Optionnaly, there can be :
    # [<tt>:reachable</tt>]
    #   the contact is reachable through the optional <tt>:media</tt>.
    #
    # The returned information contains new keys :
    # [<tt>:idStatus</tt>]
    #   indicates the identification process status. It's only present when the
    #   created contact was created with the +:individualInfos+ or
    #   +:legalEntityInfos+ extensions.
    # [<tt>:nhStatus</tt>]
    #   is a boolean indicating wether the contact is really new, or if there
    #   was already a contact with the exact same informations in the database,
    #   in which case, it has been returned.
    def contact_create(contact)
      super # placeholder so that I can add some doc
    end

    def contact_create_process(xml) #:nodoc:
      ret = super
      if (creData = xml.xpath('epp:extension/frnic:ext/frnic:resData/frnic:creData', EPPClient::SCHEMAS_URL)).size > 0
        ret[:nhStatus] = creData.xpath('frnic:nhStatus', EPPClient::SCHEMAS_URL).attr('new').value == '1'
        ret[:idStatus] = creData.xpath('frnic:idStatus', EPPClient::SCHEMAS_URL).text
      end
      ret
    end

    # Extends the EPPClient::Domain#domain_create to make sure there's no
    # <tt>:ns</tt>, <tt>:dsData</tt> or <tt>:keyData</tt> records, AFNIC's
    # servers sends quite a strange error when there is.
    def domain_create(args)
      fail ArgumentError, "You can't create a domain with ns records, you must do an update afterwards" if args.key?(:ns)
      fail ArgumentError, "You can't create a domain with ds or key records, you must do an update afterwards" if args.key?(:dsData) || args.key?(:keyData)
      super
    end

    # Raises an exception, as contacts are deleted with a garbage collector.
    def contact_delete(_args)
      fail NotImplementedError, 'Contacts are deleted with a garbage collector'
    end

    def contact_update_xml(args) #:nodoc:
      ret = super

      return ret unless [:add, :rem].any? { |c| args.key?(c) && [:list, :reachable, :idStatus].any? { |k| args[c].key?(k) } }

      ext = extension do |xml|
        xml.ext(:xmlns => EPPClient::SCHEMAS_URL['frnic']) do
          xml.update do
            xml.contact do
              [:add, :rem].each do |c|
                next unless args.key?(c) && [:list, :reachable, :idStatus].any? { |k| args[c].key?(k) }
                xml.__send__(c) do
                  xml.list(args[c][:list]) if args[c].key?(:list)
                  xml.idStatus(args[c][:idStatus]) if args[c].key?(:idStatus)
                  if args[c].key?(:reachable)
                    reachable = args[c][:reachable]

                    fail ArgumentError, 'reachable has to be a Hash' unless reachable.is_a?(Hash)

                    xml.reachable(reachable, 1)
                  end
                end
              end
            end
          end
        end
      end

      insert_extension(ret, ext)
    end

    # Extends the EPPClient::Contact#contact_update so that the specific AFNIC
    # update informations can be sent, the additionnal informations are :
    #
    # [<tt>:add</tt>/<tt>:rem</tt>]
    #   adds or removes the following datas :
    #   [<tt>:list</tt>]
    #     with the value of +restrictedPublication+ mean that the element
    #     diffusion should/should not be restricted.
    #   [<tt>:idStatus</tt>]
    #     indicates the identification process status.
    #   [<tt>:reachable</tt>]
    #     the contact is reachable through the optional <tt>:media</tt>.
    def contact_update(args)
      super # placeholder so that I can add some doc
    end

    # Extends the EPPClient::Domain#domain_update so that AFNIC's weirdnesses
    # can be taken into account.
    #
    # AFNIC does not support ns/hostObj, only ns/hostAttr/Host*, so, take care
    # of this here.
    # Also, you can only do one of the following at a time :
    # * update contacts
    # * update name servers
    # * update status & authInfo
    def domain_update(args)
      if args.key?(:chg) && args[:chg].key?(:registrant)
        fail ArgumentError, 'You need to do a trade or recover operation to change the registrant'
      end
      has_contacts = args.key?(:add) && args[:add].key?(:contacts) || args.key?(:add) && args[:add].key?(:contacts)
      has_ns = args.key?(:add) && args[:add].key?(:ns) || args.key?(:add) && args[:add].key?(:ns)
      has_other = args.key?(:add) && args[:add].key?(:status) || args.key?(:add) && args[:add].key?(:status) || args.key?(:chg) && args[:chg].key?(:authInfo)
      if [has_contacts, has_ns, has_other].count { |v| v } > 1
        fail ArgumentError, "You can't update all that at one time"
      end
      [:add, :rem].each do |ar|
        if args.key?(ar) && args[ar].key?(:ns) && args[ar][:ns].first.is_a?(String)
          args[ar][:ns] = args[ar][:ns].map { |ns| { :hostName => ns } }
        end
      end
      super
    end

    # Extends the EPPClient::Poll#poll_req to be able to parse quallification
    # response extension.
    def poll_req
      super # placeholder so that I can add some doc
    end

    EPPClient::Poll::PARSERS['frnic:ext/frnic:resData/frnic:quaData/frnic:contact'] = :contact_afnic_qualification

    def contact_afnic_qualification(xml) #:nodoc:
      contact = xml.xpath('epp:extension/frnic:ext/frnic:resData/frnic:quaData/frnic:contact', EPPClient::SCHEMAS_URL)
      ret = { :id => contact.xpath('frnic:id', EPPClient::SCHEMAS_URL).text }
      qP = contact.xpath('frnic:qualificationProcess', EPPClient::SCHEMAS_URL)
      ret[:qualificationProcess] = { :s => qP.attr('s').value }
      ret[:qualificationProcess][:lang] = qP.attr('lang').value if qP.attr('lang')
      if (leI = contact.xpath('frnic:legalEntityInfos', EPPClient::SCHEMAS_URL)).size > 0
        ret[:legalEntityInfos] = legalEntityInfos(leI)
      end
      reach = contact.xpath('frnic:reachability', EPPClient::SCHEMAS_URL)
      ret[:reachability] = { :reStatus => reach.xpath('frnic:reStatus', EPPClient::SCHEMAS_URL).text }
      if (voice = reach.xpath('frnic:voice', EPPClient::SCHEMAS_URL)).size > 0
        ret[:reachability][:voice] = voice.text
      end
      if (email = reach.xpath('frnic:email', EPPClient::SCHEMAS_URL)).size > 0
        ret[:reachability][:email] = email.text
      end
      ret
    end

    EPPClient::Poll::PARSERS['frnic:ext/frnic:resData/frnic:trdData/frnic:domain'] = :domain_afnic_trade_response

    def domain_afnic_trade_response(xml) #:nodoc:
      dom = xml.xpath('epp:extension/frnic:ext/frnic:resData/frnic:trdData/frnic:domain', EPPClient::SCHEMAS_URL)
      ret = {
        :name     => dom.xpath('frnic:name', EPPClient::SCHEMAS_URL).text,
        :trStatus => dom.xpath('frnic:trStatus', EPPClient::SCHEMAS_URL).text,
        :reID     => dom.xpath('frnic:reID', EPPClient::SCHEMAS_URL).text,
        :reDate   => DateTime.parse(dom.xpath('frnic:reDate', EPPClient::SCHEMAS_URL).text),
        :acID     => dom.xpath('frnic:acID', EPPClient::SCHEMAS_URL).text,
      }

      # FIXME: there are discrepencies between the 1.2 xmlschema, the documentation and the reality, I'm trying to stick to reality here.
      %w(reHldID acHldID).each do |f|
        if (field = dom.xpath("frnic:#{f}", EPPClient::SCHEMAS_URL)).size > 0
          ret[f.to_sym] = field.text
        end
      end
      %w(rhDate ahDate).each do |f|
        if (field = dom.xpath("frnic:#{f}", EPPClient::SCHEMAS_URL)).size > 0
          ret[f.to_sym] = DateTime.parse(field.text)
        end
      end
      ret
    end

    # keep that at the end.
    include EPPClient::RGP
    include EPPClient::SecDNS
  end
end
