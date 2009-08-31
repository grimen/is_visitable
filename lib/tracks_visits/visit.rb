# coding: utf-8

class Visit < ActiveRecord::Base
  
  belongs_to :visitable, :polymorphic => true
  belongs_to :visitor, :polymorphic => true
  
end