#!/usr/bin/env rake
require 'rake'
require 'rdoc/task'
require 'rubygems/package_task'
require "bundler/gem_tasks"

desc "Generate documentation for the Rails framework"
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'doc/rdoc'
  rdoc.title    = "Documentation"

  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.options << '--charset' << 'utf-8'

  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('ChangeLog')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

