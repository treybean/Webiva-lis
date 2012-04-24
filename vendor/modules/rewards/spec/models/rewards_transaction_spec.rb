require  File.expand_path(File.dirname(__FILE__)) + "/../rewards_spec_helper"

describe RewardsTransaction do

  reset_domain_tables :rewards_user, :rewards_transaction, :end_user, :end_user_cache

  before(:each) do
    @options = Rewards::AdminController.module_options :rewards_value => 10
    Configuration.set_config_model(@options)
  end

  it "should require an user" do
    @user = RewardsTransaction.new
    @user.valid?

    @user.should have(1).error_on(:rewards_user_id)
    @user.should have(1).error_on(:amount)
    @user.should have(1).error_on(:transaction_type)
  end

  it "should work with cart" do
    @end_user = EndUser.push_target('test@test.dev')
    @user = RewardsUser.push_user @end_user.id
    @user.update_attribute :rewards, 1000
    @transaction = @user.rewards_transactions.create :amount => 25, :transaction_type => 'credit', :used => true
    @user.reload
    @user.rewards.should == 1025
    @transaction.end_user_id.should == @end_user.id
    @transaction.cart_price(nil, nil).should == 0.1
    @transaction.coupon?.should be_true
    @transaction.cart_shippable?.should be_false

    cart = mock :real_items => 0
    @transaction.cart_limit(nil, cart).should == 0

    cart = mock :real_items => 1, :full_price => 10
    @transaction.cart_limit(nil, cart).should == 100

    cart = mock :real_items => 1, :full_price => 10000
    @transaction.cart_limit(nil, cart).should == 1025
  end

  it "should update the amount when the rewards are purchased" do
    @end_user = EndUser.push_target('test@test.dev')
    @user = RewardsUser.push_user @end_user.id
    @user.update_attribute :rewards, 1000
    @transaction = @user.rewards_transactions.create :amount => 25, :transaction_type => 'debit'
    @user.reload
    @user.rewards.should == 1000
    @transaction.end_user_id.should == @end_user.id
    @transaction.cart_price(nil, nil).should == -0.1

    order_item = mock :quantity => 100
    session = {}
    @transaction.cart_post_processing @end_user, order_item, session
    @transaction.used.should be_true
    @transaction.amount.should == 100

    @user.reload
    @user.rewards.should == 900

    @transaction.cart_post_processing @end_user, order_item, session

    @user.reload
    @user.rewards.should == 900
  end

  describe "Credits" do
    before(:each) do
      @end_user = EndUser.push_target('test@test.dev')
      @user = RewardsUser.push_user @end_user.id
    end

    it "should be able to credit the user" do
      @user.rewards.should == 0
      @transaction = @user.rewards_transactions.create :amount => 25, :transaction_type => 'credit'
      @transaction.id.should_not be_nil
      @transaction.used.should be_false
      @transaction.dollar_amount.should == 2
      @user.rewards.should == 0

      @transaction.complete!
      @transaction.used.should be_true

      @user.reload
      @user.rewards.should == 25
      @user.dollar_amount.should == 2
    end
  end

  describe "Debits" do
    before(:each) do
      @end_user = EndUser.push_target('test@test.dev')
      @user = RewardsUser.push_user @end_user.id
    end

    it "should be able to debit the user" do
      @user.update_attributes :rewards => 100
      @transaction = @user.rewards_transactions.create :amount => 10, :transaction_type => 'debit'
      @transaction.id.should_not be_nil
      @transaction.used.should be_false
      @transaction.dollar_amount.should == 1
      @user.rewards.should == 100

      @transaction.complete!
      @transaction.used.should be_true

      @user.reload
      @user.rewards.should == 90
      @user.dollar_amount.should == 9
    end

    it "should not be able to debit the user if they do not have enough rewards" do
      @user.update_attributes :rewards => 100
      @transaction = @user.rewards_transactions.create :amount => 200, :transaction_type => 'debit'
      @transaction.id.should be_nil
      @transaction.should have(1).error_on(:amount)
      @user.reload
      @user.rewards.should == 100
      @user.dollar_amount.should == 10
    end
  end
end
