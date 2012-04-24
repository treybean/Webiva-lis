
class NotificationMessage < DomainModel
  belongs_to :notification_type
  belongs_to :end_user

  has_many :notification_message_tags, :dependent => :delete_all
  has_many :notification_message_users, :dependent => :delete_all

  has_many :tags, :through => :notification_message_tags

  validates_presence_of :notification_type_id
  validates_presence_of :view_type

  has_options :view_type, [['Always visible', 'always'], ['One time', 'once'], ['User clear able', 'clear'] ]

  after_save :save_tags

  named_scope :valid_messages, lambda { |time| {:conditions => ['expired = 0 AND data_model_id IS NOT NULL AND (starts_at IS NULL OR starts_at <= ?) AND (expires_at > ? OR expires_at IS NULL)', time, time]} }
  named_scope :for_type, lambda { |type| type ? {:conditions => {:notification_type_id => type}} : {} }
  named_scope :messages_for_everyone, {:conditions => {:has_tags => false, :end_user_id => nil}}
  named_scope :messages_for_user, lambda { |user_id| {:conditions => {:end_user_id => user_id}} }
  named_scope :messages_for_tags, lambda { |user| {:joins => :notification_message_tags, :conditions => ['tag_id in(?)', user.tags.collect(&:id)]} }

  content_node

  def content_model
    self.notification_type.content_model if self.notification_type
  end

  def content_node_body(language)
    return nil unless self.data_model

    self.content_model.content_model_fields.collect do |fld|
      fld.content_display(self.data_model, :excerpt)
    end.compact.join(' | ')
  end

  def data_model
    return @data_model if @data_model
    return nil unless self.content_model
    @data_model = self.content_model.content_model.find_by_id self.data_model_id if self.data_model_id
    @data_model = self.content_model.content_model.new unless @data_model
    @data_model
  end

  def data_model=(opts)
    self.data_model.attributes = opts if self.content_model
  end

  def tags=(tags)
    return if tags.nil?
    @new_tags = tags.reject(&:blank?)
    self.has_tags = @new_tags.empty? ? false : true
  end

  def type_name
    self.notification_type.name
  end

  def save_tags
    return unless @new_tags

    self.notification_message_tags.each do |t|
      t.delete unless @new_tags.include?(t.tag_id)
    end

    @new_tags.each do |tid|
      next if self.notification_message_tags.detect { |t| t.tag_id == tid }
      self.notification_message_tags.create :tag_id => tid
    end

    @new_tags = nil
  end

  def message_user(user)
    self.notification_message_users.first(:conditions => {:end_user_id => user.id}) || self.notification_message_users.build(:end_user_id => user.id)
  end

  def push_message_user(user)
    self.message_user(user).save
  end

  def cleared?(user)
    self.message_user(user).cleared
  end

  def clear(user)
    self.message_user(user).update_attributes :cleared => true
  end

  def unclear(user)
    self.message_user(user).update_attributes :cleared => false
  end

  def active?
    (! self.expired) && (self.starts_at.nil? || self.starts_at <= Time.now) && (self.expires_at.nil? || self.expires_at > Time.now)
  end

  def everyone?
    self.end_user.nil? && self.tags.empty?
  end

  def excerpt
    return "(##{self.id})" unless self.data_model
    self.content_model.content_model_fields.each do |fld|
      val = fld.content_display(self.data_model, :excerpt)
      return val unless val.blank?
    end
    "(##{self.id})"
  end

  alias_method :name, :excerpt

  def before_save
    self.expired = self.expires_at.nil? || self.expires_at > Time.now ? false : true

    if self.data_model
      self.data_model.save
      self.data_model_id = self.data_model.id
    end

    true
  end

  def self.fetch_user_messages(user, type_id, opts={})
    return [] unless user.id

    limit = opts[:limit] || 10
    now = opts[:now] || Time.now
    order = opts[:order] || 'created_at DESC'
    messages = NotificationMessage.for_type(type_id).valid_messages(now).messages_for_everyone.find :all, :include => :notification_message_users, :limit => limit, :order => order
    messages += NotificationMessage.for_type(type_id).valid_messages(now).messages_for_user(user.id).find :all, :include => :notification_message_users, :limit => limit, :order => order
    messages += NotificationMessage.for_type(type_id).valid_messages(now).messages_for_tags(user).find(:all, :include => :notification_message_users, :limit => limit, :order => order) unless user.tags.empty?
    messages = messages.reject{ |m| m.cleared?(user) }.sort{ |a,b| b.created_at <=> a.created_at }.uniq
    (1..(messages.size-limit)).each { |i| messages.pop }
    messages
  end

  def self.expire_messages
    NotificationMessage.update_all 'expired = 1', ['expires_at <= ?', Time.now]
  end
end
