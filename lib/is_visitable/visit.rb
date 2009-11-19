# coding: utf-8

module IsVisitable
  class Visit < ::ActiveRecord::Base
    
    ASSOCIATIVE_FIELDS = [
        :visitable_id,
        :vistable_type,
        :visitor_id,
        :visitor_type,
        :ip
      ].freeze
    CONTENT_FIELDS = [
        :visits
      ].freeze
      
    # Associations.
    belongs_to :visitable, :polymorphic => true
    belongs_to :visitor, :polymorphic => true
    
    # Aliases.
    alias :object :visitable
    alias :owner  :visitor
    
    # Named scopes: Order.
    named_scope :in_order,            :order => 'created_at ASC'
    named_scope :most_recent,         :order => 'created_at DESC'
    named_scope :lowest_visits,       :order => 'visits ASC'
    named_scope :highest_visits,      :order => 'visits DESC'
    
    # Named scopes: Filters.
    named_scope :limit,               lambda { |number_of_items|      {:limit => number_of_items} }
    named_scope :since,               lambda { |created_at_datetime|  {:conditions => ['created_at >= ?', created_at_datetime]} }
    named_scope :recent,              lambda { |arg|
                                        if [::ActiveSupport::TimeWithZone, ::DateTime].any? { |c| c.is_a?(arg) }
                                          {:conditions => ['created_at >= ?', arg]}
                                        else
                                          {:limit => arg.to_i}
                                        end
                                      }
    named_scope :between_dates,       lambda { |from_date, to_date|     {:conditions => {:created_at => (from_date..to_date)}} }
    named_scope :with_visits,         lambda { |visits_value_or_range|  {:conditions => {:visits => visits_value_or_range}} }
    named_scope :of_visitable_type,   lambda { |type|       {:conditions => Support.polymorphic_conditions_for(type, :visitable, :type)} }
    named_scope :by_visitor_type,     lambda { |type|       {:conditions => Support.polymorphic_conditions_for(type, :visitor, :type)} }
    named_scope :on,                  lambda { |visitable|  {:conditions => Support.polymorphic_conditions_for(visitable, :visitable)} }
    named_scope :by,                  lambda { |visitor|    {:conditions => Support.polymorphic_conditions_for(visitor, :visitor)} }
    
  end
end