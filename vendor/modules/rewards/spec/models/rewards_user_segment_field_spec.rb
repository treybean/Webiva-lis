require  File.expand_path(File.dirname(__FILE__)) + "/../rewards_spec_helper"

describe RewardsUserSegmentField do

  reset_domain_tables :rewards_user, :rewards_transaction, :end_user, :end_user_cache

  before do
    DataCache.reset_local_cache
    test_activate_module('shop', :shop_currency => 'USD')
    test_activate_module('rewards')
  end

  after do
    SiteModule.destroy_all
  end

  before(:each) do
    @user1 = EndUser.push_target 'test1@test.dev'
    @rewards_user = RewardsUser.push_user @user1.id
    @rewards_user.rewards_transactions.create :used => true, :transaction_type => 'credit', :amount => 1000
    @rewards_user.rewards_transactions.create :used => true, :transaction_type => 'credit', :amount => 100
    @rewards_user.rewards_transactions.create :used => true, :transaction_type => 'credit', :amount => 40
    @rewards_user.rewards_transactions.create :used => true, :transaction_type => 'debit', :amount => 10
    @rewards_user.rewards_transactions.create :used => true, :transaction_type => 'debit', :amount => 100
    @rewards_user.rewards_transactions.create :used => true, :transaction_type => 'debit', :amount => 11

    @user2 = EndUser.push_target 'test2@test.dev'
    @rewards_user = RewardsUser.push_user @user2.id
    @rewards_user.rewards_transactions.create :used => true, :transaction_type => 'credit', :amount => 300
    @rewards_user.rewards_transactions.create :used => true, :transaction_type => 'credit', :amount => 41
    @rewards_user.rewards_transactions.create :used => true, :transaction_type => 'debit', :amount => 4
    @rewards_user.rewards_transactions.create :used => true, :transaction_type => 'debit', :amount => 11
  end

  it "should only have valid RewardsUser fields" do
    RewardsUser.count.should == 2

    obj = RewardsUserSegmentField.user_segment_fields_handler_info[:domain_model_class].new
    RewardsUserSegmentField.user_segment_fields.each do |key, value|
      obj.has_attribute?(value[:field]).should be_true
      obj.respond_to?(value[:display_field]).should be_true
    end
  end

  it "can output field data" do
    handler_data = RewardsUserSegmentField.get_handler_data([@user1.id, @user2.id], [:notification])

    RewardsUserSegmentField.user_segment_fields.each do |key, value|
      next if value[:search_only]
      RewardsUserSegmentField.field_output(@user1, handler_data, key)
    end
  end

  it "should be able to sort on sortable fields" do
    ids = [@user1.id, @user2.id]
    seg = UserSegment.create :name => 'Test', :segment_type => 'custom'
    seg.id.should_not be_nil
    seg.add_ids ids

    RewardsUserSegmentField.user_segment_fields.each do |key, value|
      next unless value[:sortable]
      scope = RewardsUserSegmentField.sort_scope(key.to_s, 'DESC')
      scope.should_not be_nil

      seg.order_by = key.to_s
      seg.sort_ids(ids).should be_true
      seg.status.should == 'finished'
      seg.end_user_ids.size.should == 2
    end
  end
end
