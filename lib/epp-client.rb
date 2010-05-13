# $Abso$

require 'openssl'
require 'socket'
require 'nokogiri'
require 'builder'
require 'date'

require 'epp-client/base'
require 'epp-client/xml'
require 'epp-client/session'
require 'epp-client/connection'
require 'epp-client/exceptions'
require 'epp-client/ssl'
require 'epp-client/domain'
require 'epp-client/contact'

class EPPClient
  SCHEMAS = %w[
    epp-1.0
    domain-1.0
    host-1.0
    contact-1.0
    secDNS-1.0
  ]
  SCHEMAS_RGP = %w[
    rgp-1.0
  ]

  SCHEMAS_URL = SCHEMAS.inject({}) do |a,s|
    a[s.sub(/-1\.0$/, '')] = "urn:ietf:params:xml:ns:#{s}" if s =~ /-1\.0$/
    a[s] = "urn:ietf:params:xml:ns:#{s}"
    a
  end


  include Base
  include XML
  include Session
  include Connection
  include SSL
  include Domain
  include Contact

end
