require File.expand_path(File.dirname(__FILE__)) + "/../../rewards_spec_helper"

describe Rewards::Trigger do

  reset_domain_tables :rewards_user, :rewards_transaction, :end_user, :end_user_cache

  def create_trigger(data)
    ta = mock :data => data
    Rewards::Trigger::RewardTrigger.new ta
  end

  before(:each) do
    @end_user = EndUser.push_target 'test@test.dev'
    @end_user_source = EndUser.push_target 'test-source@test.dev'
    @end_user.update_attribute :source_user_id, @end_user_source.id
    @end_user.reload
  end

  it "should add rewards to the user" do
    @trigger = create_trigger :credit_source_user => false, :amount => 10

    assert_difference 'RewardsUser.count', 1 do
      assert_difference 'RewardsTransaction.count', 1 do
        data = {}
        @trigger.perform data, @end_user
      end
    end

    @user = RewardsUser.push_user @end_user.id
    @user.rewards.should == 10

    @user = RewardsUser.push_user @end_user_source.id
    @user.rewards.should == 0
  end

  it "should add rewards to the user's source" do
    @trigger = create_trigger :credit_source_user => true, :amount => 10

    assert_difference 'RewardsUser.count', 1 do
      assert_difference 'RewardsTransaction.count', 1 do
        data = {}
        @trigger.perform data, @end_user
      end
    end

    @user = RewardsUser.push_user @end_user.id
    @user.rewards.should == 0

    @user = RewardsUser.push_user @end_user_source.id
    @user.rewards.should == 10
  end
end
