
class RewardsUser < DomainModel
  has_end_user :end_user_id
  has_many :rewards_transactions, :dependent => :destroy

  validates_presence_of :end_user_id

  def rewards_value
    @rewards_value ||= Rewards::AdminController.module_options.rewards_value
  end

  def credit_rewards(amount)
    self.update_attribute :rewards, self.rewards + amount
  end

  def debit_rewards(amount)
    total = self.rewards - amount
    total = 0 if total < 0
    self.update_attribute :rewards, total
  end

  def dollar_amount
    (self.rewards / self.rewards_value).to_i
  end

  def self.push_user(end_user_id)
    RewardsUser.find_by_end_user_id(end_user_id) || RewardsUser.create(:end_user_id => end_user_id)
  end
end
