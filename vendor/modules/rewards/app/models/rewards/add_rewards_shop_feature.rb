
class Rewards::AddRewardsShopFeature < Shop::ProductFeature

  def self.shop_product_feature_handler_info
    { 
      :name => 'Add rewards to a user',
      :callbacks => [ :purchase ],
      :options_partial => "/rewards/features/add_rewards"
    }
  end
  
  def purchase(user, order_item, session)
    rewards_user = nil

    if options.credit_source_user
      rewards_user = RewardsUser.push_user(user.source_user.id) if user.source_user
    else
      rewards_user = RewardsUser.push_user user.id
    end

    rewards_user.rewards_transactions.create(:amount => options.amount, :transaction_type => 'credit', :used => true, :note => '[Shop feature rewards for "%s"]' / order_item.item_name) if rewards_user
  end

  def self.options(val)
    Options.new(val)
  end
  
  class Options < HashModel
    attributes :credit_source_user => true, :amount => 0
    validates_presence_of :amount
    integer_options :amount
    boolean_options :credit_source_user

    options_form(
                 fld(:credit_source_user, :yes_no, :description => "the rewards are for the source user only"),
                 fld(:amount, :text_field, :unit => 'rewards')
                 )

    def validate
      self.errors.add(:amount, 'is invalid') if self.amount && self.amount <= 0
    end
  end
  
  
  def self.description(opts)
    opts = self.options(opts)
    sprintf("Credit %d rewards to the %s", opts.amount, opts.credit_source_user ? "user's source" : "user")
  end
end
