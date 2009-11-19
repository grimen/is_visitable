# coding: utf-8
require File.join(File.dirname(__FILE__), *%w[is_visitable visit])
require File.join(File.dirname(__FILE__), *%w[is_visitable visitor])
require File.join(File.dirname(__FILE__), *%w[is_visitable visitable])
require File.join(File.dirname(__FILE__), *%w[is_visitable support])

module IsVisitable
  
  extend self
  
  class IsVisitableError < ::StandardError
    def initialize(message)
      ::IsVisitable.log message, :debug
      super message
    end
  end
  
  InvalidConfigValueError = ::Class.new(IsVisitableError)
  InvalidVisitorError = ::Class.new(IsVisitableError)
  InvalidVisitValueError = ::Class.new(IsVisitableError)
  RecordError = ::Class.new(IsVisitableError)
  
  mattr_accessor :verbose
  
  @@verbose = ::Object.const_defined?(:RAILS_ENV) ? (::RAILS_ENV.to_sym == :development) : true
  
  def log(message, level = :info)
    return unless @@verbose
    level = :info if level.blank?
    @@logger ||= ::Logger.new(::STDOUT)
    @@logger.send(level.to_sym, message)
  end
  
  def root
    @@root ||= File.expand_path(File.join(File.dirname(__FILE__), *%w[..]))
  end
  
end