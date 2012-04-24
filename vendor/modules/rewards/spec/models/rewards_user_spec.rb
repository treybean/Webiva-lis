require  File.expand_path(File.dirname(__FILE__)) + "/../rewards_spec_helper"

describe RewardsUser do

  reset_domain_tables :rewards_user, :end_user, :end_user_cache

  it "should require an end user" do
    @user = RewardsUser.new
    @user.valid?

    @user.should have(1).error_on(:end_user_id)
  end
end
