# $Abso$
Gem::Specification.new do |s|
  s.name = 'epp-client'
  s.version = '0.9'
  s.date = '2010-05-14'
  s.author = 'Mathieu Arnold'
  s.email = 'm@absolight.fr'
  s.summary = 'An extensible EPP client library'
  s.description = 'An extensible EPP client library.'

  s.files = Dir[ "README", "ChangeLog", "lib/**/*.rb"]

  s.has_rdoc = true

  s.required_ruby_version = '>= 1.8.7'
  s.add_dependency('nokogiri', '~> 1.4.0')
  s.add_dependency('builder',  '~> 2.1.2')
end

