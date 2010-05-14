# $Abso$

# RFC3915[http://tools.ietf.org/html/rfc3915]
#
# Domain Registry Grace Period Mapping for the
# Extensible Provisioning Protocol (EPP)
#
module EPPClient::RGP
  def self.included(base) # :nodoc:
    base.class_eval do
      alias_method :initialize_without_rgp, :initialize
      alias_method :initialize, :initialize_with_rgp
      alias_method :domain_info_process_without_rgp, :domain_info_process
      alias_method :domain_info_process, :domain_info_process_with_rgp
    end
  end

  def initialize_with_rgp(args) #:nodoc:
    initialize_without_rgp(args)
    @extensions << EPPClient::SCHEMAS_URL['rgp']
  end

  def domain_info_process_with_rgp(xml) #:nodoc:
    ret = domain_info_process_without_rgp(xml)
    if (rgp_status = xml.xpath('epp:extension/rgp:infData/rgp:rgpStatus', EPPClient::SCHEMAS_URL)).size > 0
      ret[:rgpStatus] = rgp_status.map {|s| s.attr('s')}
    end
    ret
  end
end
