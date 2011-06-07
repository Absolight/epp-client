# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'epp-client/version'

Gem::Specification.new do |s|
  s.name         = 'epp-client'
  s.version      = EPPClient::VERSION
  s.platform     = Gem::Platform::RUBY
  s.date         = '2010-05-14'
  s.authors      = ['Mathieu Arnold']
  s.email        = ['m@absolight.fr']
  s.summary      = 'An extensible EPP client library'
  s.description  = 'An extensible EPP client library.'

  s.required_ruby_version = '>= 1.8.7'
  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "epp-client"

  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables  = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_path = 'lib'

  s.add_development_dependency "bundler", ">= 1.0.0.rc.5"
  s.add_dependency('nokogiri', '~> 1.4.0')
  s.add_dependency('builder',  '>= 2.1.2')
end

