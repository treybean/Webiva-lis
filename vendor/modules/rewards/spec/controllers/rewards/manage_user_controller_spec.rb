require  File.expand_path(File.dirname(__FILE__)) + '/../../rewards_spec_helper'

describe Rewards::ManageUserController do

  reset_domain_tables :rewards_user, :rewards_transaction, :end_user, :end_user_cache

  before(:each) do
    @options = Rewards::AdminController.module_options :rewards_value => 10
    Configuration.set_config_model(@options)

    mock_editor
    @user = EndUser.push_target('test@test.dev')
  end

  it "should render the view page" do
    assert_difference 'RewardsUser.count', 1 do
      get "view", :path => [@user.id]
    end
  end

  it "should handle user table list" do 
    controller.should handle_active_table(:transaction_table) do |args|
      args[:path] = [@user.id]
      post 'transaction_table', args
    end
  end

 it "should render the transaction page" do
    assert_difference 'RewardsUser.count', 1 do
      get "transaction", :path => [@user.id]
    end
  end

 it "should be able to credit the user" do
    assert_difference 'RewardsUser.count', 1 do
      assert_difference 'RewardsTransaction.count', 1 do
        post "transaction", :path => [@user.id], :commit => true, :transaction => {:amount => 100, :transaction_type => 'credit', :note => ''}
      end
    end

    @rewards_user = RewardsUser.push_user @user.id
    @rewards_user.rewards.should == 100
  end

  it "should be able to deduct rewards" do
    @rewards_user = RewardsUser.push_user @user.id
    @rewards_user.rewards_transactions.create :transaction_type => 'credit', :used => true, :amount => 1000

    assert_difference 'RewardsUser.count', 0 do
      assert_difference 'RewardsTransaction.count', 1 do
        post "transaction", :path => [@user.id], :commit => true, :transaction => {:amount => 100, :transaction_type => 'debit'}
      end
    end

    @rewards_user.reload
    @rewards_user.rewards.should == 900
  end
end
