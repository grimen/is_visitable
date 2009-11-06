# coding: utf-8

module TracksVisits #:nodoc:
  module Visitor
    
    DEFAULT_CLASS_NAME = begin
      if defined?(Account)
        :account
      else
        :user
      end
    rescue
      :user
    end
    
  end
end