class ForumPost < DomainModel
  attr_accessor :subscribe, :tag_names

  belongs_to :forum_forum
  belongs_to :forum_topic
  has_end_user :end_user_id, :name_column => :posted_by
  belongs_to :moderated_by, :class_name => 'EndUser'
  has_many :forum_post_attachments

  validates_presence_of :body, :subject, :posted_by, :forum_forum_id

  cached_content :update => [ :forum_forum, :forum_topic ]

  safe_content_filter(:body => :body_html)  do |post|
    { :filter => post.forum_forum.content_filter,
      :folder_id => post.forum_forum.folder_id
    }
  end

  named_scope :approved_posts, :conditions => 'forum_posts.approved = 1'


  def moderated(end_user)
    self.moderated_at = Time.now
    self.moderated_by = end_user
  end

  def sticky
    self.forum_topic.sticky
  end

  def sticky=(sticky)
    self.forum_topic.sticky = sticky
  end

  def before_validation_on_create
    if self.posted_by.nil?
      self.posted_by = self.end_user ? self.end_user.name : 'Anonymous'.t
    end

    if self.subject.blank? && self.forum_topic
      self.subject = self.forum_topic.default_subject
    end
  end

  def before_update
    if self.changed.include?('body')
      self.edited_at = Time.new
    end
  end

  def before_create
    if self.forum_topic.nil?
      topic = self.build_forum_topic :subject => self.subject, :posted_by => self.posted_by,
	                      :end_user_id => self.end_user_id, :forum_forum_id => self.forum_forum_id,
	                      :content_type => self.content_type, :content_id => self.content_id, :tag_names => self.tag_names || ''
      topic.save_content(self.end_user)
      self.forum_topic_id = topic.id
    end

    self.first_post = self.forum_topic.forum_posts.count == 0
    self.posted_at = Time.new
  end

  def after_create
    self.forum_topic.last_post = self
    self.forum_topic.last_posted_at = self.posted_at
    self.forum_topic.refresh_activity_count
    self.forum_topic.refresh_posts_count
    self.forum_topic.save
  end

  def after_update
    if self.changed.include?('approved')
      self.forum_topic.refresh_posts_count
      self.forum_topic.save_content(self.end_user)
    end
  end

  def after_destroy
    self.forum_topic.refresh_posts_count
    self.forum_topic.save
  end

  def attachment
    return @attachment if @attachment
    file = self.forum_post_attachments.find(:first)
    if file
      @attachment = file.domain_file
    else
      nil
    end
  end

  def attachment_id
    return @attachment_id if @attachment_id
    file = self.forum_post_attachments.find(:first)
    if file
      @attachment_id = file.domain_file.id
    else
      nil
    end
  end

  def attachment_id=(id)
    id = id.to_i
    @attachment_id = id if id > 0
  end

  def content_id
    return @content_id if @content_id
    @content_id = self.forum_topic ? self.forum_topic.content_id : nil
  end

  def content_id=(id)
    @content_id = id.to_i
  end

  def content_type
    return @content_type if @content_type
    @content_type = self.forum_topic ? self.forum_topic.content_type : nil
  end

  def content_type=(type)
    @content_type = type
  end

  def after_save
    if @attachment_id
      file = self.forum_post_attachments.find(:first)
      if ! file
	file = self.forum_post_attachments.new( :end_user => self.end_user, :forum_post => self )
      end
      file.domain_file_id = @attachment_id
      file.save
      @attachment_id = nil
    end
  end

  def can_add_attachments?
    self.forum_forum.can_add_attachments_to_posts?
  end

  def upload_folder
    self.forum_forum.upload_folder
  end

  def upload_folder_id
    self.forum_forum.upload_folder_id
  end

  def valid_file_size?(size)
    self.forum_forum.valid_file_size?(size)
  end

  def validate
    if self.attachment_id
      file = DomainFile.find self.attachment_id
      unless self.valid_file_size?(file.file_size)
	errors.add_to_base('Attachment is too large')
      end
    end
  end

  def send_subscriptions!(data, default_subscription_template_id)
    mail_template = self.forum_forum.subscription_template
    if mail_template.nil?
      mail_template = MailTemplate.find_by_id default_subscription_template_id if default_subscription_template_id
    end
    return if mail_template.nil?

    subscribers = self.forum_topic.forum_subscriptions.find(:all, :joins => :end_user, :select => 'forum_subscriptions.*, end_users.email', :conditions => 'end_users.email is not null')
    return if subscribers.length == 0

    url = Configuration.domain_link(data[:url])

    variables = { :url => url,
                  :link => "<a href='#{url}'>#{url}</a>",
                  :topic => h(self.forum_topic.subject[0..45]),
                  :post_count => self.forum_topic.forum_posts_count,
                  :forum => self.forum_forum.name,
                  :category => self.forum_forum.forum_category.name,
                  :body => self.body[0..500],
                  :body_formatted => (self.body[0..500].gsub("\n","<br/>"))
                }

    subscribers.each do |subscriber|
      mail_template.deliver_to_address(subscriber.email, variables)
    end
  end
end
