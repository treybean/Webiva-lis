
class Rewards::Trigger < Trigger::TriggeredActionHandler

  def self.trigger_actions_handler_info
    { :name => 'Rewards Triggered Actions' }
  end

  register_triggered_actions [
    { :name => :reward,
      :description => 'Credit the user rewards',
      :options_partial => '/rewards/trigger/reward'
    }
  ]

  class RewardTrigger < Trigger::TriggerBase #:nodoc:

    class RewardOptions < HashModel
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

    options "Reward Options", RewardOptions

    def perform(data={},user = nil)
      @data = data
    
      if user
        rewards_user = nil

        if options.credit_source_user
          rewards_user = RewardsUser.push_user(user.source_user.id) if user.source_user
        else
          rewards_user = RewardsUser.push_user user.id
        end

        rewards_user.rewards_transactions.create(:amount => options.amount, :transaction_type => 'credit', :used => true, :note => '[Reward Trigger rewards]') if rewards_user
      end
    end
  end
end
