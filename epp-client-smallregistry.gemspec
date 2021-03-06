# -*- encoding: utf-8 -*-
require File.expand_path('../lib/epp-client/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'epp-client-smallregistry'
  gem.version       = EPPClient::VERSION
  gem.authors       = ['Mathieu Arnold']
  gem.email         = ['m@absolight.fr']
  gem.description   = 'Smallregistry EPP client library.'
  gem.summary       = 'Smallregistry EPP client library'
  gem.homepage      = 'https://github.com/Absolight/epp-client'

  gem.required_ruby_version = '>= 1.8.7'
  gem.required_rubygems_version = '>= 1.3.6'

  gem.files = [
    'ChangeLog',
    'EXAMPLE.SMALLREGISTRY',
    'Gemfile',
    'MIT-LICENSE',
    'README',
    'Rakefile',
    'epp-client-smallregistry.gemspec',
    'lib/epp-client/smallregistry.rb',
    'vendor/smallregistry/sr-1.0.xsd',
  ]

  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.require_paths = ['lib']

  gem.add_development_dependency 'bundler', '>= 1.0.0'
  gem.add_dependency('nokogiri', '~> 1.4')
  gem.add_dependency('builder',  '>= 2.1.2')
  gem.add_dependency('epp-client-base', EPPClient::VERSION.to_s)
  gem.add_dependency('epp-client-secdns', EPPClient::VERSION.to_s)
end
