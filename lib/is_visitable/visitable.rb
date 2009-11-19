# coding: utf-8
require File.join(File.dirname(__FILE__), 'visit')
require File.join(File.dirname(__FILE__), 'visitor')

unless defined?(::Visit)
  class Visit < ::IsVisitable::Visit
  end
end

module IsVisitable #:nodoc:
  module Visitable
    
    ASSOCIATION_CLASS = ::Visit
    CACHABLE_FIELDS = [
        :total_visits_count,
        :unique_visits_count
      ].freeze
    DEFAULTS = {
        :accept_ip => false
      }.freeze
    
    def self.included(base) #:nodoc:
      base.class_eval do
        extend ClassMethods
      end
      
      # Checks if this object visitable or not.
      #
      def visitable?; false; end
      alias :is_visitable? :visitable?
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
      def is_visitable(*args)
        options = args.extract_options!
        options.reverse_merge!(
            :by         => nil,
            :accept_ip  => options[:anonymous] || DEFAULTS[:accept_ip] # i.e. also accepts unique IPs as visitor
          )
          
        # Assocations: Visit class (e.g. Visit).
        options[:visit_class] = ASSOCIATION_CLASS
        
        # Had to do this here - not sure why. Subclassing Visit should be enough? =S
        "::#{options[:visit_class]}".constantize.class_eval do
          belongs_to :visitable, :polymorphic => true unless self.respond_to?(:visitable)
          belongs_to :visitor,   :polymorphic => true unless self.respond_to?(:visitor)
        end
        
        # Visitor class(es).
        options[:visitor_classes] = [*options[:by]].collect do |class_name|
          begin
            class_name.to_s.singularize.classify.constantize
          rescue NameError => e
            raise InvalidVisitorError, "Visitor class #{class_name} not defined, needs to be defined. #{e}"
          end
        end
        
        # Assocations: Visitor class(es) (e.g. User, Account, ...).
        options[:visitor_classes].each do |visitor_class|
          if ::Object.const_defined?(visitor_class.name.to_sym)
            visitor_class.class_eval do
              has_many :visits, :as => :visitor, :dependent  => :delete_all
                
              # Polymorphic has-many-through not supported (has_many :visitables, :through => :visits), so:
              # TODO: Implement with :join
              def visitables(*args)
                query_options = args.extract_options!
                query_options[:include] = [:visitable]
                query_options.reverse_merge!(:conditions => Support.polymorphic_conditions_for(self, :visitor))
                
                ::Visit.find(:all, query_options).collect! { |visit| visit.visitable }
              end
            end
          end
        end
        
        # Assocations: Visitable class (e.g. Page).
        self.class_eval do
          has_many :visits, :as => :visitable, :dependent  => :delete_all
          
          # Polymorphic has-many-through not supported (has_many :visitors, :through => :visits), so:
          # TODO: Implement with :join
          def visitors(*args)
            query_options = args.extract_options!
            query_options[:include] = [:visitor]
            query_options.reverse_merge!(:conditions => Support.polymorphic_conditions_for(self, :visitable))
              
            ::Visit.find(:all, query_options).collect! { |visit| visit.visitor }
          end
          
          # Hooks.
          before_create :init_visitable_caching_fields
          
          include ::IsVisitable::Visitable::InstanceMethods
          extend  ::IsVisitable::Visitable::Finders
        end
        
        # Save the initialized options for this class.
        self.write_inheritable_attribute :is_visitable_options, options
        self.class_inheritable_reader :is_visitable_options
      end
      
      # Does this class count/track visits?
      #
      def visitable?
        @@visitable ||= self.respond_to?(:is_visitable_options, true)
      end
      alias :is_visitable? :visitable?
      
      protected
        
        # Check if the requested visitor object is a valid visitor.
        #
        def validate_visitor(identifiers)
          raise InvalidVisitorError, "Argument can't be nil: no visitor object or IP provided." if identifiers.blank?
          visitor = identifiers[:by] || identifiers[:visitor] || identifiers[:user] || identifiers[:ip]
          is_ip = Support.is_ip?(visitor)
          visitor = visitor.to_s.strip if is_ip
          
          unless Support.is_active_record?(visitor) || is_ip
            raise InvalidVisitorError, "Visitor is of wrong type: #{visitor.inspect}."
          end
          raise InvalidVisitorError, "Visit based on IP is disabled." if is_ip && !self.is_visitable_options[:accept_ip]
          visitor
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
      def unique_visits(recalculate = false)
        if !recalculate && self.visitable_caching_fields?(:unique_visits)
          self.unique_visits || 0
        else
          ::Visit.count(:conditions => self.visitable_conditions)
        end
      end
      alias :number_of_visitors :unique_visits
      
      # Get the total number of visits for this object.
      #
      def total_visits(recalculate = false)
        if !recalculate && self.visitable_caching_fields?(:total_visits)
          self.total_visits || 0
        else
          ::Visit.sum(:visits, :conditions => self.visitable_conditions)
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
        self.visits.exists?(:conditions => visitor_conditions(identifiers))
      end
      alias :is_visited_by? :visited_by?
      
      def visit_by(identifiers)
        self.visits.find(:first, :conditions => visitor_conditions(identifiers))
      end
      
      # Delete all tracked visits for this visitable object.
      #
      def reset_visits!
        self.visits.delete_all
        self.total_visits = 0 if self.visitable_caching_fields?(:total_visits)
        self.unique_visits = 0 if self.visitable_caching_fields?(:unique_visits)
      end
      
      # View the object with and identifier (user or ip) - create new if new visitor.
      #
      # === Identifiers hash:
      # * <tt>:visitor/:user/:account</tt> - identify with a visitor-model or IP (e.g. User, Account, ..., "128.0.0.1")
      # * <tt>:*</tt> - Any custom visit field, e.g. :visitor_type => "duck" (optional)
      #
      def visit!(identifiers_and_options)
        begin
          visitor = self.validate_visitor(identifiers_and_options)
          visit = self.visit_by(identifiers_and_options)
          
          # Except for the reserved fields, any Visit-fields should be be able to update.
          visit_values = identifiers_and_options.except(*::IsVisitable::Visit::ASSOCIATIVE_FIELDS)
          
          unless visit.present?
            # An un-existing visitor of this visitable object => Create a new visit.
            visit = ::Visit.new do |v|
              v.visitable_id    = self.id
              v.visitable_type  = self.class.name
              
              if Support.is_active_record?(visitor)
                v.visitor_id   = visitor.id
                v.visitor_type = visitor.class.name
              else
                v.ip = visitor
              end
              
              v.visits = 0
            end
            self.visits << visit
          else
            # An existing visitor of this visitable object => Update the existing visit.
          end
          is_new_record = visit.new_record?
          
          # Update non-association attributes and any custom fields.
          visit.attributes = visit_values.slice(*visit.attribute_names.collect { |an| an.to_sym })
          
          visit.visits += 1
          visit.save && self.save_without_validation
          
          if self.visitable_caching_fields?(:total_visits)
            begin
              self.cached_total_visits += 1 if is_new_record
            rescue
              self.cached_total_visits = self.total_visits(true)
            end
          end
          
          if self.visitable_caching_fields?(:unique_visits)
            begin
              self.cached_unique_visits += 1 if is_new_record
            rescue
              self.cached_unique_visits = self.unique_visits(true)
            end
          end
          
          visit
        rescue InvalidVisitorError => e
          raise e
        rescue Exception => e
          raise RecordError, "Could not create/update visit #{visit.inspect} by #{visitor.inspect}: #{e}"
        end
      end
      
      protected
        
        # Cachable fields for this visitable class.
        #
        def visitable_caching_fields
          CACHABLE_FIELDS
        end
        
        # Checks if there are any cached fields for this visitable/trackable class.
        #
        def visitable_caching_fields?(*fields)
          fields = CACHABLE_FIELDS if fields.blank?
          fields.all? { |field| self.attributes.has_key?(:"cached_#{field}") }
        end
        alias :has_visitable_caching_fields? :visitable_caching_fields?
        
        # Initialize any cached fields.
        #
        def init_visitable_caching_fields
          self.cached_total_visits = 0 if self.visitable_caching_fields?(:total_visits)
          self.cached_unique_visits = 0 if self.visitable_caching_fields?(:unique_visits)
        end
        
        def visitable_conditions(as_array = false)
          conditions = {:visitable_id => self.id, :visitable_type => self.class.name}
          as_array ? Support.hash_conditions_as_array(conditions) : conditions
        end
        
        # Generate query conditions.
        #
        def visitor_conditions(identifiers, as_array = false)
          visitor = self.validate_visitor(identifiers)
          if Support.is_active_record?(visitor)
            conditions = {:visitor_id => visitor.id, :visitor_type => visitor.class.name}
          else
            conditions = {:ip => visitor.to_s}
          end
          as_array ? Support.hash_conditions_as_array(conditions) : conditions
        end
        
        def validate_visitor(identifiers)
          self.class.send(:validate_visitor, identifiers)
        end
        
    end
    
    module Finders
      
      # TODO: Finders
      #
      # * users that visited this, also visited [...]
      
    end
    
  end
end

# Extend ActiveRecord.
::ActiveRecord::Base.class_eval do
  include ::IsVisitable::Visitable
end
