require  File.expand_path(File.dirname(__FILE__)) + '/../../rewards_spec_helper'

describe Rewards::ManageController do

  reset_domain_tables :rewards_user, :rewards_transaction, :end_user, :end_user_cache

  before(:each) do
    @options = Rewards::AdminController.module_options :rewards_value => 10
    Configuration.set_config_model(@options)

    mock_editor
  end

  it "should handle user table list" do 
    controller.should handle_active_table(:user_table) do |args|
      args[:path] = []
      post 'user_table', args
    end
  end

  it "should handle user table list" do 
    controller.should handle_active_table(:transaction_table) do |args|
      args[:path] = []
      post 'user_table', args
    end
  end

  it "should render the users page" do
    get "users"
  end

  it "should render the transactions page" do
    get "transactions", :path => []
  end

  it "should render the transactions page for a user" do
    @user = EndUser.push_target('test@test.dev')
    @rewards_user = RewardsUser.push_user @user.id
    get "transactions", :path => [@rewards_user.id]
  end
end
