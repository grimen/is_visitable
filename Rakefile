# coding: utf-8
require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

NAME = "tracks_visits"
SUMMARY = %Q{Rails: Track unique and total visits/viewings of an ActiveRecord resource based on user/account or IP.}
HOMEPAGE = "http://github.com/grimen/#{NAME}/tree/master"
AUTHOR = "Jonas Grimfelt"
EMAIL = "grimen@gmail.com"
SUPPORT_FILES = %w(README.textile)

begin
  gem 'technicalpickles-jeweler', '>= 1.2.1'
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = NAME
    gem.summary = SUMMARY
    gem.description = SUMMARY
    gem.homepage = HOMEPAGE
    gem.author = AUTHOR
    gem.email = EMAIL
    
    gem.require_paths = %w{lib}
    gem.files = SUPPORT_FILES << %w(MIT-LICENSE Rakefile) << Dir.glob(File.join('{lib,test,rails}', '**', '*'))
    gem.executables = %w()
    gem.extra_rdoc_files = SUPPORT_FILES
  end
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

desc %Q{Run unit tests for "#{NAME}".}
task :default => :test

desc %Q{Run unit tests for "#{NAME}".}
Rake::TestTask.new(:test) do |test|
  test.libs << %w(lib test)
  test.pattern = File.join('test', '**', '*_test.rb')
  test.verbose = true
end

desc %Q{Generate documentation for "#{NAME}".}
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = NAME
  rdoc.options << '--line-numbers' << '--inline-source' << '--charset=UTF-8'
  rdoc.rdoc_files.include(SUPPORT_FILES)
  rdoc.rdoc_files.include(File.join('lib', '**', '*.rb'))
end