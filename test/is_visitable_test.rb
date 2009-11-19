# coding: utf-8
require 'test_helper'

class IsVisitableTest < Test::Unit::TestCase
  
  def setup
    @visit = ::Visit.new
    @user_1 = ::User.create
    @user_2 = ::User.create
    @tracked_post = ::TrackedPost.create
    @tracked_post_with_ip = ::TrackedPostWithIp.create
  end
  
  context "initialization" do
    
    should "extend ActiveRecord::Base" do
      assert_respond_to ::ActiveRecord::Base, :is_visitable
    end
    
    should "declare is_visitable instance methods for visitable objects" do
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
      assert_equal(@tracked_post_with_ip.visits.size, 0)
    end
    
    should "count visits based on IP correctly" do
      number_of_unique_visits = @tracked_post_with_ip.unique_visits
      number_of_total_visits = @tracked_post_with_ip.total_visits
      
      @tracked_post_with_ip.visit!(:visitor => '128.0.0.0')
      @tracked_post_with_ip.visit!(:visitor => '128.0.0.1')
      @tracked_post_with_ip.visit!(:visitor => '128.0.0.1')
      
      assert_equal number_of_unique_visits + 2, @tracked_post_with_ip.unique_visits
      assert_equal number_of_total_visits + 3, @tracked_post_with_ip.total_visits
    end
    
    should "count visits based on visitor object (user/account) correctly" do
      number_of_unique_visits = @tracked_post_with_ip.unique_visits
      number_of_total_visits = @tracked_post_with_ip.total_visits
      
      @tracked_post_with_ip.visit!(:visitor => @user_1)
      @tracked_post_with_ip.visit!(:visitor => @user_2)
      @tracked_post_with_ip.visit!(:visitor => @user_2)
      
      assert_equal number_of_unique_visits + 2, @tracked_post_with_ip.unique_visits
      assert_equal number_of_total_visits + 3, @tracked_post_with_ip.total_visits
    end
    
    should "count visits based on both IP and visitor object (user/account) correctly" do
      number_of_unique_visits = @tracked_post_with_ip.unique_visits
      number_of_total_visits = @tracked_post_with_ip.total_visits
      
      @tracked_post_with_ip.visit!(:visitor => '128.0.0.0')
      @tracked_post_with_ip.visit!(:visitor => '128.0.0.0')
      @tracked_post_with_ip.visit!(:visitor => @user_1)
      @tracked_post_with_ip.visit!(:visitor => @user_2)
      @tracked_post_with_ip.visit!(:visitor => @user_2)
      
      assert_equal number_of_unique_visits + 3, @tracked_post_with_ip.unique_visits
      assert_equal number_of_total_visits + 5, @tracked_post_with_ip.total_visits
    end
    
    should "delete all visits upon reset" do
      @tracked_post_with_ip.visit!(:visitor => '128.0.0.0')
      @tracked_post_with_ip.reset_visits!
      
      assert_equal 0, @tracked_post_with_ip.unique_visits
      assert_equal 0, @tracked_post_with_ip.total_visits
    end
  end
  
  context "visitor" do
    
    # Nothing
    
  end
  
  context "visit" do
    
    # Nothing
    
  end
  
end