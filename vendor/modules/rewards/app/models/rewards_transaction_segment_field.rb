
class RewardsTransactionSegmentField < UserSegment::FieldHandler

  def self.user_segment_fields_handler_info
    {
      :name => 'Rewards Transaction Fields',
      :domain_model_class => RewardsTransaction
    }
  end

  class TransactionType < UserSegment::FieldType

    def self.select_options
      RewardsTransaction.transaction_type_select_options
    end

    register_operation :is, [['Type', :model, {:class => RewardsTransactionSegmentField::TransactionType}]]

    def self.is(cls, group_field, field, action)
      cls.scoped(:conditions => ["#{field} = ?", action])
    end
  end

  register_field :num_rewards_transaction, UserSegment::CoreType::CountType, :field => :end_user_id, :name => '# Rewards Transactions', :display_method => 'count', :sort_method => 'count', :sortable => true, :scope => {:conditions => 'used = 1'}

  register_field :rewards_transaction_amount, UserSegment::CoreType::NumberType, :field => :amount, :name => 'Rewards Transaction: Amount', :display_method => 'sum', :sort_method => 'sum', :display_methods => [['Rewards Transaction: Amount (Max)', 'max'], ['Rewards Transaction: Amount (Min)', 'min']], :sort_methods => [['Rewards Transaction: Amount (Max)', 'max'], ['Rewards Transaction: Amount (Min)', 'min']], :sortable => true, :scope => {:conditions => 'used = 1'}

  register_field :rewards_transaction_occurred, UserSegment::CoreType::DateTimeType, :field => :updated_at, :display_method => 'max', :sort_method => 'max', :display_methods => [['Rewards Transaction: Ordered at (Last)', 'max'], ['Rewards Transaction: Ordered at (First)', 'min']], :sort_methods => [['Rewards Transaction: Ordered at (Last)', 'max'], ['Rewards Transaction: Ordered at (First)', 'min']], :sortable => true, :scope => {:conditions => 'used = 1'}

  register_field :rewards_transaction_type, RewardsTransactionSegmentField::TransactionType, :field => :transaction_type, :name => 'Rewards Transaction: Type', :sortable => true, :scope => {:conditions => 'used = 1'}

  def self.sort_scope(order_by, direction)
    info = UserSegment::FieldHandler.sortable_fields[order_by.to_sym]
    sort_method = info[:sort_method]
    field = info[:field]

    if sort_method
      RewardsTransaction.scoped(:select => "end_user_id, #{sort_method}(#{field}) as #{field}_#{sort_method}", :group => :end_user_id, :order => "#{field}_#{sort_method} #{direction}")
    else
      RewardsTransaction.scoped(:order => "#{field} #{direction}")
    end
  end

  def self.get_handler_data(ids, fields)
    RewardsTransaction.find(:all, :conditions => {:end_user_id => ids}).group_by(&:end_user_id)
  end

  def self.field_output(user, handler_data, field)
    UserSegment::FieldType.field_output(user, handler_data, field)
  end
end
