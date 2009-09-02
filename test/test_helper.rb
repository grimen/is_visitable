# coding: utf-8
require 'rubygems'

gem 'test-unit', '>= 2.0.0'
gem 'thoughtbot-shoulda', '>= 2.0.0'
gem 'sqlite3-ruby', '>= 1.2.0'
gem 'nakajima-acts_as_fu', '>= 0.0.5'
gem 'jgre-monkeyspecdoc', '>= 0.9.5'

require 'test/unit'
require 'shoulda'
require 'acts_as_fu'
require 'monkeyspecdoc'

require 'test_helper'

require 'tracks_visits'

# To get ZenTest to get it.
# require File.expand_path(File.join(File.dirname(__FILE__), 'tracks_visits_test.rb'))

build_model :visits do
  references  :visitable,     :polymorphic => true
  
  references  :visitor,       :polymorphic => true
  string      :ip,            :limit => 24
  
  integer     :visits,        :default => 0
  
  timestamps
end

build_model :guests do
end

build_model :users do
  string :username
end

build_model :untracked_posts do
end

build_model :tracked_posts do
  tracks_visits :from => :users
end

build_model :cached_tracked_posts do
  integer :unique_visits_count
  integer :total_visits_count
  
  tracks_visits :from => :users
end