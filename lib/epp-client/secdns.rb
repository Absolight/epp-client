module EPPClient::SecDNS
  SCHEMAS_SECDNS = %w[
    secDNS-1.1
  ]

  EPPClient::SCHEMAS_URL.merge!(SCHEMAS_SECDNS.inject({}) do |a,s|
    a[s.sub(/-1\.1$/, '')] = "urn:ietf:params:xml:ns:#{s}" if s =~ /-1\.1$/
    a[s] = "urn:ietf:params:xml:ns:#{s}"
    a
  end)

  def initialize(args)
    super
    @extensions << EPPClient::SCHEMAS_URL['secDNS-1.1']
  end
end
