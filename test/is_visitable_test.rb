# coding: utf-8
require 'test_helper'

class IsVisitableTest < Test::Unit::TestCase
  
  def setup
    @visit = ::Visit.new
    
    @user = ::User.create
    @user_2 = ::User.create
    @user_3 = ::User.create
    @guest = ::Guest.create
    @account = ::Account.create
    
    @unvisitable_post = ::Post.create
    @visitable_post = ::VisitablePost.create
    @visitable_post_with_ip = ::VisitablePostWithIp.create
  end
  
  context "initialization" do
    
    should "extend ActiveRecord::Base" do
      assert_respond_to ::ActiveRecord::Base, :is_visitable
      assert_respond_to ::ActiveRecord::Base, :is_visitable?
    end
    
    should "declare is_visitable instance methods for visitable objects" do
      public_instance_methods = [
          [:is_visitable?, :visitable?],
          :first_visited_at,
          :last_visited_at,
          :unique_visits,
          :total_visits,
          :reset_visits!,
          [:is_visited?, :visited?],
          [:is_visited_by?, :visited_by?],
          :visit_by,
          :visit!,
          :visits
        ].flatten
        
      #assert methods.all? { |m| @visitable_post.respond_to?(m) }
      # assert !methods.any? { |m| @visitable_post.respond_to?(m) }
      assert public_instance_methods.all? { |m| @visitable_post.respond_to?(m) }
      assert !public_instance_methods.all? { |m| @unvisitable_post.respond_to?(m) }
    end
    
    # Don't work for some reason... =S
    should "be enabled only for specified models" do
      assert @visitable_post.visitable?
      assert !@unvisitable_post.visitable?
    end
    
  end
  
  context "visitable" do
    should "have zero visits from the beginning" do
      assert_equal(@visitable_post.visits.size, 0)
      assert_equal(@visitable_post_with_ip.visits.size, 0)
    end
    
    context "visitor type" do
      should "not accept any reviews on IP if disabled" do
        assert_raise ::IsVisitable::InvalidVisitorError do
          @visitable_post.visit!(:by => '128.0.0.0')
        end
      end
    end
    
    context "visits counting" do
      
      context "only IP visitors" do
        should "count each IP-visit only once" do
          number_of_unique_visits = @visitable_post_with_ip.unique_visits
          number_of_total_visits = @visitable_post_with_ip.total_visits
          
          @visitable_post_with_ip.visit!(:by => '128.0.0.0')
          @visitable_post_with_ip.visit!(:by => '128.0.0.1')
          @visitable_post_with_ip.visit!(:by => '128.0.0.1')
          
          assert_equal number_of_unique_visits + 2, @visitable_post_with_ip.unique_visits
          assert_equal number_of_total_visits + 3, @visitable_post_with_ip.total_visits
        end
      end
      
      context "only ActiveRecord visitors" do
        should "count each ActiveRecord-visit only once" do
          number_of_unique_visits = @visitable_post.unique_visits
          number_of_total_visits = @visitable_post.total_visits
          
          @visitable_post.visit!(:by => @user_2)
          @visitable_post.visit!(:by => @user_3)
          @visitable_post.visit!(:by => @user_3)
          
          assert_equal number_of_unique_visits + 2, @visitable_post.unique_visits
          assert_equal number_of_total_visits + 3, @visitable_post.total_visits
        end
      end
      
      context "both IP and ActiveRecord visitors" do
        should "count each IP and ActiveRecord-visit only once" do
          number_of_unique_visits = @visitable_post_with_ip.unique_visits
          number_of_total_visits = @visitable_post_with_ip.total_visits
          
          @visitable_post_with_ip.visit!(:by => '128.0.0.0')
          @visitable_post_with_ip.visit!(:by => '128.0.0.0')
          @visitable_post_with_ip.visit!(:by => @user_2)
          @visitable_post_with_ip.visit!(:by => @user_3)
          @visitable_post_with_ip.visit!(:by => @user_3)
          
          assert_equal number_of_unique_visits + 3, @visitable_post_with_ip.unique_visits
          assert_equal number_of_total_visits + 5, @visitable_post_with_ip.total_visits
        end
      end
      
    end
    
    should "delete all visits upon reset" do
      @visitable_post_with_ip.visit!(:by => '128.0.0.0')
      @visitable_post_with_ip.reset_visits!
      
      assert_equal 0, @visitable_post_with_ip.unique_visits
      assert_equal 0, @visitable_post_with_ip.total_visits
    end
  end
  
  context "visitor" do
    
    context "associations" do
      should "have many visits" do
        assert @user.respond_to?(:visits)
        assert @account.respond_to?(:visits)
        assert !@guest.respond_to?(:visits)
        
        VisitablePost.create.visit!(:by => @user)
        VisitablePost.create.visit!(:by => @user)
        
        assert_equal 2, @user.visits.size
      end
      
      should "have many visitables" do
        assert @user.respond_to?(:visitables)
        assert @account.respond_to?(:visitables)
        assert !@guest.respond_to?(:visitables)
        
        VisitablePost.create.visit!(:by => @user)
        VisitablePost.create.visit!(:by => @user)
        VisitablePost.create.visit!(:by => @user)
        
        assert_equal 3, @user.visitables.size
      end
    end
    
  end
  
  context "visit" do
    
    # Nothing
    
  end
  
end