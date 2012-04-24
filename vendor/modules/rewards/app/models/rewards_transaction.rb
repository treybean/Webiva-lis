
class RewardsTransaction < DomainModel
  belongs_to :rewards_user
  has_end_user :admin_user_id
  has_end_user :end_user_id

  validates_presence_of :rewards_user_id
  validates_presence_of :amount
  validates_presence_of :transaction_type

  has_options :transaction_type, [['Credit', 'credit'], ['Debit', 'debit']]

  def validate
    if self.amount
      self.errors.add(:amount, 'is invalid') if self.amount < 0
      self.errors.add(:amount, 'is too large') if self.debit? && self.amount > self.rewards_user.rewards
    end
  end

  def credit?
    self.transaction_type == 'credit'
  end

  def debit?
    self.transaction_type == 'debit'
  end

  def rewards_value
    self.rewards_user.rewards_value
  end

  def complete!
    self.update_attributes :used => true
  end

  def dollar_amount
    (self.amount / self.rewards_value).to_i
  end

  def before_create
    self.end_user_id = self.rewards_user.end_user_id
  end

  def after_save
    if self.used && self.used_changed?
      self.credit? ? self.rewards_user.credit_rewards(self.amount) : self.rewards_user.debit_rewards(self.amount)
    end
  end

  # cart functions

  def name
    "Rewards"
  end

  def coupon?
    true
  end

  def cart_details(options,cart)
    ''
  end

  def cart_shippable?
    false
  end
  
  def cart_sku
    "REWARDS"
  end

  def cart_price(options,cart)
    price = 1.0 / self.rewards_value.to_f
    self.debit? ? -price : price
  end

  def cart_limit(options,cart)
    return 0 if cart.real_items == 0

    max_rewards = (cart.full_price * self.rewards_value).to_i
    return max_rewards if max_rewards < self.rewards_user.rewards

    self.rewards_user.rewards
  end

  def cart_post_processing(user,order_item,session)
    return if self.used?

    self.amount = order_item.quantity
    self.complete!
  end     
end
