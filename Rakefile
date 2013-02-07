#!/usr/bin/env rake
require 'rake'
require 'rdoc/task'
require 'rubygems/package_task'
require "bundler/gem_helper"

MY_GEMS = Dir['*.gemspec'].map {|g| g.sub(/.*-(.*)\.gemspec/, '\1')}

MY_GEMS.each do |g|
  namespace g do
    bgh = Bundler::GemHelper.new(Dir.pwd, "epp-client-#{g}")
    bgh.install
    task :push do
      sh "gem push #{File.join(Dir.pwd, 'pkg', "epp-client-#{g}-#{bgh.__send__(:version)}.gem")}"
    end
  end
end

namespace :all do
  task :build   => MY_GEMS.map { |f| "#{f}:build"   }
  task :install => MY_GEMS.map { |f| "#{f}:install" }
  task :push    => MY_GEMS.map { |f| "#{f}:push"    }
end

task :build   => 'all:build'
task :install => 'all:install'
task :push => 'all:push'

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

