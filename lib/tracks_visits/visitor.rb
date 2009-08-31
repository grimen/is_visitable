# coding: utf-8
require File.join(File.dirname(__FILE__), 'tracks_visits_error')

module TracksVisits #:nodoc:
  module ActiveRecord #:nodoc:
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
      DEFAULT_CLASS_NAME.freeze
      
      def self.included(base) #:nodoc:
        base.class_eval do
          include InstanceMethods
          extend ClassMethods
        end
      end
      
      module ClassMethods
        
        # Nothing
        
      end
      
      module InstanceMethods
        
        # Nothing
        
      end
      
    end
  end
end