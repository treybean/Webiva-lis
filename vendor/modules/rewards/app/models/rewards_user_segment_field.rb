
class RewardsUserSegmentField < UserSegment::FieldHandler

  def self.user_segment_fields_handler_info
    {
      :name => 'Rewards Fields',
      :domain_model_class => RewardsUser
    }
  end

  register_field :rewards, UserSegment::CoreType::SimpleNumberType, :field => :rewards, :name => 'Rewards', :sortable => true
  register_field :rewards_created, UserSegment::CoreType::DateTimeType, :field => :created_at, :name => 'Rewards: Created', :sortable => true, :builder_name => 'Rewards created when?'
  register_field :rewards_updated, UserSegment::CoreType::DateTimeType, :field => :updated_at, :name => 'Rewards: Updated', :sortable => true, :builder_name => 'Rewards updated when?'

  def self.sort_scope(order_by, direction)
    field = self.user_segment_fields[order_by.to_sym][:field]
    RewardsUser.scoped :order => "rewards_users.#{field} #{direction}"
  end

  def self.get_handler_data(ids, fields)
    RewardsUser.find(:all, :conditions => {:end_user_id => ids}).index_by(&:end_user_id)
  end

  def self.field_output(user, handler_data, field)
    UserSegment::FieldType.field_output(user, handler_data, field)
  end
end
