# coding: utf-8
require 'test_helper'

class TracksVisitsTest < Test::Unit::TestCase
  
  def setup
    @user_1 = ::User.create
    @user_2 = ::User.create
    @tracked_post = ::TrackedPost.create
    @regular_post = ::TrackedPost.create
  end
  
  context "initialization" do
    
    should "extend ActiveRecord::Base" do
      assert_respond_to ::ActiveRecord::Base, :tracks_visits
    end
    
    should "declare tracks_visits instance methods for visitable objects" do
      methods = [
          :first_visited_at,
          :first_visited_at,
          :last_visited_at,
          :unique_visits,
          :total_visits,
          :visited_by?,
          :reset_visits!,
          :visitable?,
          :visit!
        ]
        
      assert methods.all? { |m| @tracked_post.respond_to?(m) }
      # assert !methods.any? { |m| @tracked_post.respond_to?(m) }
    end
    
    # Don't work for some reason... =S
    # should "be enabled only for specified models" do
    #   assert @tracked_post.visitable?
    #   assert_not @untracked_post.visitable?
    # end
    
  end
  
  context "visitable" do
    should "have zero visits from the beginning" do
      assert_equal(@tracked_post.visits.size, 0)
    end
    
    should "count visits based on IP correctly" do
      number_of_unique_visits = @tracked_post.unique_visits
      number_of_total_visits = @tracked_post.total_visits
      
      @tracked_post.visit!(:ip => '128.0.0.0')
      @tracked_post.visit!(:ip => '128.0.0.1')
      @tracked_post.visit!(:ip => '128.0.0.1')
      
      assert_equal @tracked_post.unique_visits, number_of_unique_visits + 2
      assert_equal @tracked_post.total_visits, number_of_total_visits + 3
    end
    
    should "count visits based on visitor object (user/account) correctly" do
      number_of_unique_visits = @tracked_post.unique_visits
      number_of_total_visits = @tracked_post.total_visits
      
      @tracked_post.visit!(:user => @user_1)
      @tracked_post.visit!(:user => @user_2)
      @tracked_post.visit!(:user => @user_2)
      
      assert_equal @tracked_post.unique_visits, number_of_unique_visits + 2
      assert_equal @tracked_post.total_visits, number_of_total_visits + 3
    end
    
    should "count visits based on both IP and visitor object (user/account) correctly" do
      number_of_unique_visits = @tracked_post.unique_visits
      number_of_total_visits = @tracked_post.total_visits
      
      @tracked_post.visit!(:ip => '128.0.0.0')
      @tracked_post.visit!(:ip => '128.0.0.0')
      @tracked_post.visit!(:user => @user_1)
      @tracked_post.visit!(:user => @user_2)
      @tracked_post.visit!(:user => @user_2)
      
      assert_equal @tracked_post.unique_visits, number_of_unique_visits + 3
      assert_equal @tracked_post.total_visits, number_of_total_visits + 5
    end
    
    should "delete all visits upon reset" do
      @tracked_post.visit!(:ip => '128.0.0.0')
      @tracked_post.reset_visits!
      
      assert_equal @tracked_post.unique_visits, 0
      assert_equal @tracked_post.total_visits, 0
    end
  end
  
  context "visitor" do
    
    # Nothing
    
  end
  
  context "visit" do
    
    # Nothing
    
  end
  
end