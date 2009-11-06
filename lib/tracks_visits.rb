# coding: utf-8
require File.join(File.dirname(__FILE__), *%w[tracks_visits visit])
require File.join(File.dirname(__FILE__), *%w[tracks_visits visitor])
require File.join(File.dirname(__FILE__), *%w[tracks_visits visitable])
require File.join(File.dirname(__FILE__), *%w[tracks_visits support])

module TracksVisits
  
  extend self
  
  class TracksVisitsError < ::StandardError
    def initialize(message)
      ::TracksVisits.log message, :debug
      super message
    end
  end
  
  InvalidConfigValueError = ::Class.new(TracksVisitsError)
  InvalidVisitorError = ::Class.new(TracksVisitsError)
  InvalidVisitValueError = ::Class.new(TracksVisitsError)
  
  mattr_accessor :verbose
  
  @@verbose = ::Object.const_defined?(:RAILS_ENV) ? (::RAILS_ENV.to_sym == :development) : true
  
  def log(message, level = :info)
    return unless @@verbose
    level = :info if level.blank?
    @@logger ||= ::Logger.new(::STDOUT)
    @@logger.send(level.to_sym, message)
  end
  
end