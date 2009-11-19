# coding: utf-8

class IsVisitableMigration < ActiveRecord::Migration
  def self.up
    create_table :visits do |t|
      t.references  :visitable,     :polymorphic => true
      
      t.references  :visitor,       :polymorphic => true
      t.string      :ip,            :limit => 24
      
      t.integer     :visits,        :default => 1
      
      # created_at <=> first_visited_at
      # updated_at <=> last_visited_at
      t.timestamps
    end
    
    add_index :visits, [:visitor_id, :visitor_type]
    add_index :visits, [:visitable_id, :visitable_type]
  end
  
  def self.down
    drop_table :visits
  end
end
