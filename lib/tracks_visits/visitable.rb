# coding: utf-8
require File.join(File.dirname(__FILE__), 'tracks_visits_error')
require File.join(File.dirname(__FILE__), 'visit')
require File.join(File.dirname(__FILE__), 'visitor')

module TracksVisits #:nodoc:
  module ActiveRecord #:nodoc:
    module Visitable
      
      DEFAULT_VISIT_CLASS_NAME = :visit.freeze
      
      def self.included(base) #:nodoc:
        base.class_eval do
          extend ClassMethods
        end
      end
      
      module ClassMethods
        
        # Make the model visitable, i.e. count/track visits by user/account of IP.
        # 
        # * Adds a <tt>has_many :visits</tt> association to the model for easy retrieval of the detailed visits.
        # * Adds a <tt>has_many :visitors</tt> association to the object.
        # * Adds a <tt>has_many :visits</tt> associations to the visitor class.
        #
        # === Options
        # * <tt>:options[:visit_class]</tt> - class of the model used for the visits. Defaults to Visit. 
        #   This class will be dynamically created if not already defined. If the class is predefined, 
        #   it must have in it the following definitions:
        #   <tt>belongs_to :visitable, :polymorphic => true</tt>
        #   <tt>belongs_to :visitor, :class_name => 'User', :foreign_key => :visitor_id</tt> replace user with
        #   the visitor class if needed.
        # * <tt>:options[:visitor_class]</tt> - class of the model that creates the visit.
        #   Defaults to User or Account - auto-detected. This class will NOT be created, so it must be defined in the app.
        #   Use the IP address to prevent multiple visits from the same client.
        #
        def tracks_visits(options = {})
          send :include, ::TracksVisits::ActiveRecord::Visitable::InstanceMethods
          
          # Set default class names if not given.
          options[:visitor_class_name] ||= options[:from] || Visitor::DEFAULT_CLASS_NAME
          options[:visitor_class_name] = options[:visitor_class_name].to_s.classify
          
          options[:visit_class_name] = DEFAULT_VISIT_CLASS_NAME.to_s.classify
          
          options[:visitor_class] = options[:visitor_class_name].constantize rescue nil
          
          # Assocations: Visit class (e.g. Visit).
          options[:visit_class] = begin
            options[:visit_class_name].constantize
          rescue
            # If note defined...define it!
            Object.const_set(options[:visit_class_name].to_sym, Class.new(::ActiveRecord::Base)).class_eval do
              belongs_to :visitable, :polymorphic => true
              belongs_to :visitor, :polymorphic => true
            end
            options[:visit_class_name].constantize
          end
          
          # Save the initialized options for this class.
          write_inheritable_attribute(:tracks_visits_options, options.slice(:visit_class, :visitor_class))
          class_inheritable_reader :tracks_visits_options
          
          # Assocations: Visitor class (e.g. User).
          if Object.const_defined?(options[:visitor_class].name.to_sym)
            options[:visitor_class].class_eval do
              has_many :visits,
                :foreign_key => :visitor_id,
                :class_name => options[:visit_class].name
            end
          end
          
          # Assocations: Visitable class (e.g. Page).
          self.class_eval do
            has_many options[:visit_class].name.tableize.to_sym,
              :as => :visitable,
              :dependent  => :delete_all,
              :class_name => options[:visit_class].name
              
            has_many options[:visitor_class].name.tableize.to_sym,
              :through      => options[:visit_class].name.tableize,
              :class_name   => options[:visitor_class].name
              
            # Hooks.
            before_create :init_has_visits_fields
          end
          
        end
        
        # Does this class count/track visits?
        #
        def visitable?
          self.respond_do?(:tracks_visits_options)
        end
        alias :is_visitable? :visitable?
        
        protected
          
          def validate_visitor(identifiers)
            raise TracksVisitsError, "Not initilized correctly" unless defined?(:tracks_visits_options)
            raise TracksVisitsError, "Argument can't be nil: no IP and/or user provided" if identifiers.blank?
            
            visitor = identifiers[:visitor] || identifiers[:user] || identifiers[:account]
            ip = identifiers[:ip]
            
            #tracks_visits_options[:visitor_class].present?
            #  raise TracksVisitsError, "Visitor is of wrong type: #{visitor.class}" unless (visitor.nil? || visitor.is_a?(tracks_visits_options[:visitor_class]))
            #end
            raise TracksVisitsError, "IP is of wrong type: #{ip.class}" unless (ip.nil? || ip.is_a?(String))
            raise TracksVisitsError, "Arguments not supported: no ip and/or user provided" unless ((visitor && visitor.id) || ip)
            
            [visitor, ip]
          end
          
      end
      
      module InstanceMethods
        
        # Does this object count/track visits?
        #
        def visitable?
          self.class.visitable?
        end
        alias :is_visitable? :visitable?
        
        # first_visit = created_at.
        #
        def first_visited_at
          self.created_at if self.respond_to?(:created_at)
        end
        
        # last_visit = updated_at.
        #
        def last_visited_at
          self.updated_at if self.respond_to?(:updated_at)
        end
        
        # Get the unique number of visits for this object based on the visits field, 
        # or with a SQL query if the visited objects doesn't have the visits field
        #
        def unique_visits
          if self.has_cached_fields?
            self.unique_visits || 0
          else
            self.visits.size
          end
        end
        alias :number_of_visitors :unique_visits
        
        # Get the total number of visits for this object.
        #
        def total_visits
          if self.has_cached_fields?
            self.total_visits || 0
          else
            tracks_visits_options[:visit_class].sum(:visits, :conditions => {:visitable_id => self.id})
          end
        end
        alias :number_of_visits :total_visits
        
        # Is this object visited by anyone?
        #
        def visited?
          self.unique_visits > 0
        end
        alias :is_visited? :visited?
        
        # Check if an item was already visited by the given visitor or ip.
        #
        # === Identifiers hash:
        # * <tt>:ip</tt> - identify with IP
        # * <tt>:visitor</tt> - identify with a visitor-model (e.g. User, ...)
        # * <tt>:user</tt> - (same as above)
        # * <tt>:account</tt> - (same as above)
        #
        def visited_by?(identifiers)
          visitor, ip = self.validate_visitor(identifiers)
          
          conditions = if visitor.present?
            {:visitor => visitor}
          else # ip
            {:ip => (ip ? ip.to_s.strip : nil)}
          end
          self.visits.count(:conditions => conditions) > 0
        end
        alias :is_visited_by? :visited_by?
        
        # Delete all tracked visits for this visitable object.
        #
        def reset_visits!
          self.visits.delete_all
          self.total_visits_count = self.unique_visits_count = 0 if self.has_cached_fields?
        end
        
        # View the object with and identifier (user or ip) - create new if new visitor.
        #
        # === Identifiers hash:
        # * <tt>:ip</tt> - identify with IP
        # * <tt>:visitor</tt> - identify with a visitor-model (e.g. User, ...)
        # * <tt>:user</tt> - (same as above)
        # * <tt>:account</tt> - (same as above)
        #
        def visit!(identifiers)
          visitor, ip = self.validate_visitor(identifiers)
          
          begin
            # Count unique visits only, based on account or IP.
            visit = self.visits.find_by_visitor_id(visitor.id) if visitor.present?
            visit ||= self.visits.find_by_ip(ip) if ip.present?
            
            # Try to get existing visit for the current visitor, 
            # or create a new otherwise and set new attributes.
            if visit.present?
              visit.visits += 1
              
              unique_visit = false
            else
              visit = tracks_visits_options[:visit_class].new do |v|
                #v.visitor = visitor
                #v.visitable = self
                v.visitable_id    = self.id
                v.visitable_type  = self.class.name
                v.visitor_id      = visitor.id if visitor
                v.visitor_type    = visitor.class.name if visitor
                v.ip              = ip if ip.present?
                v.visits          = 1
              end
              self.visits << visit
              
              unique_visit = true
            end
            
            visit.save
            
            # Maintain cached value if cached field is available.
            #
            if self.has_cached_fields?
              self.unique_visits += 1 if unique_visit
              self.total_visits += 1
              self.save_without_validation
            end
            
            true
          rescue Exception => e
            raise TracksVisitsError, "Database transaction failed: #{e}"
            false
          end
        end
        
        protected
          
          # Is there a cached fields for this visitable class?
          #
          def cached_fields?
            self.attributes.has_key?(:total_visits_count) && self.attributes.has_key?(:unique_visits_count)
          end
          alias :has_cached_fields? :cached_fields?
          
          # Initialize cached fields - if any.
          #
          def init_has_visits_fields
            self.total_visits = self.unique_visits = 0 if self.has_cached_fields?
          end
          
          def validate_visitor(identifiers)
            self.class.send :validate_visitor, identifiers
          end
          
      end
      
      module SingletonMethods
        
        # TODO: Finders
        
      end
      
    end
  end
end

# Extend ActiveRecord.
::ActiveRecord::Base.class_eval do
  include ::TracksVisits::ActiveRecord::Visitable
end
