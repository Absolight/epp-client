require 'epp-client/base'
require 'epp-client/rgp'

class EPPClient::AFNIC < EPPClient::Base
  SCHEMAS_AFNIC = %w[
    frnic-1.2
  ]

  EPPClient::SCHEMAS_URL.merge!(SCHEMAS_AFNIC.inject({}) do |a,s|
    a[s.sub(/-1\.2$/, '')] = "http://www.afnic.fr/xml/epp/#{s}" if s =~ /-1\.2$/
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
    if args.delete(:test) == true
      args[:server] ||= 'epp.test.nic.fr'
    else
      args[:server] ||= 'epp.nic.fr'
    end
    @services = EPPClient::SCHEMAS_URL.values_at('domain', 'contact')
    args[:port] ||= 700
    super(args)
    @extensions << EPPClient::SCHEMAS_URL['frnic']
  end

  # Extends the base domain check so that the specific afnic check
  # informations are processed, the additionnal informations are :
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
      hash = ret.select {|d| d[:name] == name.text}.first
      hash[:reserved] = name.attr('reserved').value == "1"
      unless (reason = dom.xpath('frnic:rsvReason', EPPClient::SCHEMAS_URL).text).empty?
        hash[:rsvReason] = reason
      end
      hash[:forbidden] = name.attr('forbidden').value == "1"
      unless (reason = dom.xpath('frnic:fbdReason', EPPClient::SCHEMAS_URL).text).empty?
        hash[:fbdReason] = reason
      end
    end
    return ret
  end

  # Extends the base domain info so that the specific afnic <tt>:status</tt>
  # can be added.
  def domain_info(domain)
    super # placeholder so that I can add some doc
  end

  def domain_info_process(xml) #:nodoc:
    ret = super
    if (frnic_status = xml.xpath('epp:extension/frnic:ext/frnic:resData/frnic:infData/frnic:domain/frnic:status', EPPClient::SCHEMAS_URL)).size > 0
      ret[:status] += frnic_status.map {|s| s.attr('s')}
    end
    ret
  end

  # Extends the base contact info so that the specific afnic check
  # informations are processed, the additionnal informations are :
  #
  # either :
  # [<tt>:legalEntityInfos</tt>]
  #   indicating that the contact is an organisation with the following
  #   informations :
  #   [<tt>:legalStatus</tt>]
  #     should be either +company+, +association+ or +other+.
  #   [<tt>:idStatus</tt>] indicates the identification process status.
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
  #       indicate the date of the association was declared at the
  #       prefecture.
  #     [<tt>:publ</tt>]
  #       contains informations regarding the publication in the "Journal
  #       Officiel" :
  #       [<tt>:date</tt>] the date of publication.
  #       [<tt>:page</tt>] the page the announce is on.
  #       [<tt>:announce</tt>] the announce number on the page.
  # [<tt>:individualInfos</tt>]
  #   indicating that the contact is a person with the following
  #   informations :
  #   [<tt>:idStatus</tt>] indicates the identification process status.
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
        ret[:list] = list.map {|l| l.text}
      end
      if (firstName = contact.xpath('frnic:firstName', EPPClient::SCHEMAS_URL)).size > 0
        ret[:firstName] = firstName.text
      end
      if (iI = contact.xpath('frnic:individualInfos', EPPClient::SCHEMAS_URL)).size > 0
        ret[:individualInfos] = {}
        ret[:individualInfos][:birthDate] = Date.parse(iI.xpath('frnic:birthDate', EPPClient::SCHEMAS_URL).text)
        %w(idStatus birthCity birthPc birthCc).each do |val|
          if (r = iI.xpath("frnic:#{val}", EPPClient::SCHEMAS_URL)).size > 0
            ret[:individualInfos][val.to_sym] = r.text
          end
        end
      end
      if (leI = contact.xpath('frnic:legalEntityInfos', EPPClient::SCHEMAS_URL)).size > 0
        ret[:legalEntityInfos] = {}
        ret[:legalEntityInfos][:legalStatus] = leI.xpath('frnic:legalStatus', EPPClient::SCHEMAS_URL).attr('s').value
        %w(idStatus siren VAT trademark DUNS local).each do |val|
          if (r = leI.xpath("frnic:#{val}", EPPClient::SCHEMAS_URL)).size > 0
            ret[:legalEntityInfos][val.to_sym] = r.text
          end
        end
        if (asso = leI.xpath("frnic:asso", EPPClient::SCHEMAS_URL)).size > 0
          ret[:legalEntityInfos][:asso] = {}
          if (r = asso.xpath("frnic:waldec", EPPClient::SCHEMAS_URL)).size > 0
            ret[:legalEntityInfos][:asso][:waldec] = r.text
          else
            ret[:legalEntityInfos][:asso][:decl] = Date.parse(asso.xpath('frnic:decl', EPPClient::SCHEMAS_URL).text)
            publ = asso.xpath('frnic:publ', EPPClient::SCHEMAS_URL)
            ret[:legalEntityInfos][:asso][:publ] = {
              :date => Date.parse(publ.text),
              :announce => publ.attr('announce').value,
              :page => publ.attr('page').value,
            }
          end
        end
      end
      if (obsoleted = contact.xpath('frnic:obsoleted', EPPClient::SCHEMAS_URL)).size > 0
        if obsoleted.text != '0'
          ret[:obsoleted] = {}
          ret[:obsoleted][:when] = DateTime.parse(v_when.value) if v_when = obsoleted.attr('when')
        end
      end
      if (reachable = contact.xpath('frnic:reachable', EPPClient::SCHEMAS_URL)).size > 0
        if reachable.text != '0'
          ret[:reachable] = {}
          if v_when = reachable.attr('when')
            ret[:reachable][:when] = DateTime.parse(v_when.value)
          end
          if media = reachable.attr('media')
            ret[:reachable][:media] = media.value
          end
          if source = reachable.attr('source')
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
      xml.ext( :xmlns => EPPClient::SCHEMAS_URL['frnic']) do
        xml.create do
          xml.contact do
            if contact.key?(:legalEntityInfos)
              lEI = contact[:legalEntityInfos]
              xml.legalEntityInfos do
                xml.legalStatus(:s => lEI[:legalStatus])
                [:siren, :VAT, :trademark, :DUNS, :local].each do |val|
                  if lEI.key?(val)
                    xml.__send__(val, lEI[val])
                  end
                end
                if lEI.key?(:asso)
                  asso = lEI[:asso]
                  xml.asso do
                    if asso.key?(:waldec)
                      xml.waldec(asso[:waldec])
                    else
                      xml.decl(asso[:decl])
                      xml.publ({:announce => asso[:publ][:announce], :page => asso[:publ][:page]}, asso[:publ][:date])
                    end
                  end
                end
              end
            else
              if contact.key?(:list)
                xml.list(contact[:list])
              end
              if contact.key?(:individualInfos)
                iI = contact[:individualInfos]
                xml.individualInfos do
                  xml.birthDate(iI[:birthDate])
                  if iI.key?(:birthCity)
                    xml.birthCity(iI[:birthCity])
                  end
                  if iI.key?(:birthPc)
                    xml.birthPc(iI[:birthPc])
                  end
                  xml.birthCc(iI[:birthCc])
                end
              end
              if contact.key?(:firstName)
                xml.firstName(contact[:firstName])
              end
            end
            if contact.key?(:reachable)
              if Hash === (reachable = contact[:reachable])
                xml.reachable(reachable, 1)
              else
                raise ArgumentError, "reachable has to be a Hash"
              end
            end
          end
        end
      end
    end

    insert_extension(ret, ext)
  end

  # Extends the base contact create so that the specific afnic create
  # informations can be sent, the additionnal informations are :
  #
  # either :
  # [<tt>:legalEntityInfos</tt>]
  #   indicating that the contact is an organisation with the following
  #   informations :
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
  #       indicate the date of the association was declared at the
  #       prefecture.
  #     [<tt>:publ</tt>]
  #       contains informations regarding the publication in the "Journal
  #       Officiel" :
  #       [<tt>:date</tt>] the date of publication.
  #       [<tt>:page</tt>] the page the announce is on.
  #       [<tt>:announce</tt>] the announce number on the page.
  # [<tt>:individualInfos</tt>]
  #   indicating that the contact is a person with the following
  #   informations :
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

  # Make sure there's no <tt>:ns</tt> records, AFNIC's servers sends quite
  # a strange error when there is.
  def domain_create(args)
    raise ArgumentError, "You can't create a domain with ns records, you must do an update afterwards" if args.key?(:ns)
    super
  end

  # Raises an exception, as contacts are deleted with a garbage collector.
  def contact_delete(args)
    raise NotImplementedError, "Contacts are deleted with a garbage collector"
  end

  def contact_update_xml(args) #:nodoc:
    ret = super

    if args.key?(:add) && ( args[:add].key?(:list) || args[:add].key?(:reachable) ) || args.key?(:rem) && ( args[:rem].key?(:list) || args[:rem].key?(:reachable) )
      ext = extension do |xml|
        xml.ext( :xmlns => EPPClient::SCHEMAS_URL['frnic']) do
          xml.update do
            xml.contact do
              if args.key?(:add)
                xml.add do
                  if args[:add].key?(:list) && ( args[:add].key?(:list) || args[:add].key?(:reachable) )
                    xml.list(args[:add][:list])
                  end
                  if args[:add].key?(:reachable)
                    if Hash === (reachable = args[:add][:reachable])
                      xml.reachable(reachable, 1)
                    else
                      raise ArgumentError, "reachable has to be a Hash"
                    end
                  end
                end
              end
              if args.key?(:rem) && ( args[:rem].key?(:list) || args[:rem].key?(:reachable) )
                xml.rem do
                  if args[:rem].key?(:list)
                    xml.list(args[:add][:list])
                  end
                  if args[:rem].key?(:reachable)
                    if Hash === (reachable = args[:rem][:reachable])
                      xml.reachable(reachable, 1)
                    else
                      raise ArgumentError, "reachable has to be a Hash"
                    end
                  end
                end
              end
            end
          end
        end
      end

      return insert_extension(ret, ext)
    else
      return ret
    end
  end

  # Extends the base contact update so that the specific afnic update
  # informations can be sent, the additionnal informations are :
  #
  # [<tt>:add</tt>/<tt>:rem</tt>]
  #   adds or removes the following datas :
  #   [<tt>:list</tt>]
  #     with the value of +restrictedPublication+ mean that the element
  #     diffusion should/should not be restricted.
  #   [<tt>:reachable</tt>]
  #     the contact is reachable through the optional <tt>:media</tt>.
  def contact_update(args)
    super # placeholder so that I can add some doc
  end

  # Extends the base domain update so that afnic's weirdnesses can be taken
  # into account.
  #
  # AFNIC does not support ns/hostObj, only ns/hostAttr/Host*, so, take care
  # of this here.
  # Also, you can only do one of the following at a time :
  # * update contacts
  # * update name servers
  # * update status & authInfo
  def domain_update(args)
    if args.key?(:chg) && args[:chg].key?(:registrant)
      raise ArgumentError, "You need to do a trade or recover operation to change the registrant"
    end
    has_contacts = args.key?(:add) && args[:add].key?(:contacts) || args.key?(:add) && args[:add].key?(:contacts)
    has_ns = args.key?(:add) && args[:add].key?(:ns) || args.key?(:add) && args[:add].key?(:ns)
    has_other = args.key?(:add) && args[:add].key?(:status) || args.key?(:add) && args[:add].key?(:status) || args.key?(:chg) && args[:chg].key?(:authInfo)
    if [has_contacts, has_ns, has_other].select {|v| v}.size > 1
      raise ArgumentError, "You can't update all that at one time"
    end
    [:add, :rem].each do |ar|
      if args.key?(ar) && args[ar].key?(:ns) && String === args[ar][:ns].first
        args[ar][:ns] = args[ar][:ns].map {|ns| {:hostName => ns}}
      end
    end
    super
  end

  # keep that at the end.
  include EPPClient::RGP
end
