# coding: utf-8
require File.join(File.dirname(__FILE__), 'tracks_visits', 'tracks_visits_error')
require File.join(File.dirname(__FILE__), 'tracks_visits', 'visit')
require File.join(File.dirname(__FILE__), 'tracks_visits', 'visitor')
require File.join(File.dirname(__FILE__), 'tracks_visits', 'visitable')

module TracksVisits
  
  def log(message, level = :info)
    level = :info if level.blank?
    RAILS_DEFAULT_LOGGER.send level.to_sym, message
  end
  
  extend self
  
end