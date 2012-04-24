require File.expand_path(File.dirname(__FILE__)) + "/../../rewards_spec_helper"
require 'shop/shop_order'
require File.expand_path(File.dirname(__FILE__)) + "/../../../../shop/spec/models/shop/shop_order_process_spec"

describe Rewards::AddRewardsShopFeature do
  it_should_behave_like "General Order Process"

  reset_domain_tables :shop_product_feature, :rewards_user, :rewards_transaction

  # Go through the order process with a test payment processor
  before(:each) do
    create_test_payment_processor # from ShopOrderProcessHelper
    @membership = Shop::ShopProduct.create(:name => 'Basic 1yr Membership', :price_values => { 'USD' => 25.00 })
  end
  
  it "should be able to add rewards to the user" do
    @feature = @membership.shop_product_features.build :position => 0, :feature_options => {:credit_source_user => false, :amount => 10}, :purchase_callback => 1
    @feature.shop_feature_handler = Rewards::AddRewardsShopFeature.to_s.underscore
    @feature.save
    @membership.update_attribute :purchase_callbacks, 1

    @membership.shop_product_features.count.should == 1
    @feature.should_not be_nil
    @feature.purchase_callback.should be_true
    @feature.shop_product_id.should == @membership.id

    @cart.add_product(@membership, 1)
    
    @order = create_order(@cart)

    @transaction = @order.authorize_payment(:remote_ip => '127.0.0.1' )
    
    @transaction.should be_success
    @order.state.should == 'authorized'
    
    @order.total.should == 25.00

    @capture_transaction = @order.capture_payment
    @capture_transaction.should be_success
    @order.state.should == 'paid'

    assert_difference 'RewardsTransaction.count', 1 do
      session = {}
      @order.post_process(@user,session)
    end

    @rewards_user = RewardsUser.push_user @user.id
    @rewards_user.rewards.should == 10
  end

  it "should be able to add rewards to the user's source" do
    @feature = @membership.shop_product_features.build :position => 0, :feature_options => {:credit_source_user => true, :amount => 10}, :purchase_callback => 1
    @feature.shop_feature_handler = Rewards::AddRewardsShopFeature.to_s.underscore
    @feature.save
    @membership.update_attribute :purchase_callbacks, 1

    @source_user = EndUser.push_target 'test-source@test.dev'
    @user.update_attribute :source_user_id, @source_user.id
    @user.reload

    @membership.shop_product_features.count.should == 1
    @feature.should_not be_nil
    @feature.purchase_callback.should be_true
    @feature.shop_product_id.should == @membership.id

    @cart.add_product(@membership, 1)
    
    @order = create_order(@cart)

    @transaction = @order.authorize_payment(:remote_ip => '127.0.0.1' )
    
    @transaction.should be_success
    @order.state.should == 'authorized'
    
    @order.total.should == 25.00

    @capture_transaction = @order.capture_payment
    @capture_transaction.should be_success
    @order.state.should == 'paid'

    assert_difference 'RewardsTransaction.count', 1 do
      session = {}
      @order.post_process(@user,session)
    end

    @rewards_user = RewardsUser.push_user @user.id
    @rewards_user.rewards.should == 0

    @rewards_user = RewardsUser.push_user @source_user.id
    @rewards_user.rewards.should == 10
  end
end
