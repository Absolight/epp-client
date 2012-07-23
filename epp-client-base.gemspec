# -*- encoding: utf-8 -*-
require File.expand_path('../lib/epp-client/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'epp-client-base'
  gem.version       = EPPClient::VERSION
  gem.date          = '2010-05-14'
  gem.authors       = ['Mathieu Arnold']
  gem.email         = ['m@absolight.fr']
  gem.description   = 'An extensible EPP client library.'
  gem.summary       = 'An extensible EPP client library'
  gem.homepage       = "https://github.com/Absolight/epp-client"

  gem.required_ruby_version = '>= 1.8.7'
  gem.required_rubygems_version = ">= 1.3.6"

  gem.files         = [
    'ChangeLog',
    'Gemfile',
    'MIT-LICENSE',
    'README',
    'Rakefile',
    'epp-client-base.gemspec',
    'lib/epp-client/base.rb',
    'lib/epp-client/connection.rb',
    'lib/epp-client/contact.rb',
    'lib/epp-client/domain.rb',
    'lib/epp-client/exceptions.rb',
    'lib/epp-client/poll.rb',
    'lib/epp-client/session.rb',
    'lib/epp-client/ssl.rb',
    'lib/epp-client/version.rb',
    'lib/epp-client/xml.rb',
    'vendor/ietf/contact-1.0.xsd',
    'vendor/ietf/domain-1.0.xsd',
    'vendor/ietf/epp-1.0.xsd',
    'vendor/ietf/eppcom-1.0.xsd',
    'vendor/ietf/host-1.0.xsd',
    'vendor/ietf/rfc4310.txt',
    'vendor/ietf/rfc5730.txt',
    'vendor/ietf/rfc5731.txt',
    'vendor/ietf/rfc5732.txt',
    'vendor/ietf/rfc5733.txt',
    'vendor/ietf/rfc5734.txt',
    'vendor/ietf/rfc5910.txt',
  ]

  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.require_paths = ['lib']

  gem.add_development_dependency "bundler", ">= 1.0.0"
  gem.add_dependency('nokogiri', '~> 1.4')
  gem.add_dependency('builder',  '>= 2.1.2')
end
