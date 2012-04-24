

class ForumCategory < DomainModel

  has_many :forum_forums, :dependent => :destroy
  has_many :forum_topics, :through => :forum_forums
  has_many :forum_posts, :through => :forum_forums
  belongs_to :upload_folder, :foreign_key => 'folder_id', :class_name => 'DomainFile'
  belongs_to :subscription_template, :class_name => 'MailTemplate'

  validates_presence_of :name
  validates_presence_of :content_filter

  attr_accessor :add_to_site

  cached_content :identifier => :url

  validates_numericality_of :weight, :only_integer => true
  validates_numericality_of :file_size_limit, :only_integer => true, :allow_nil => true

  include SiteAuthorizationEngine::Target
  access_control :admin_permission
  access_control :post_permission

  def self.filter_user_options
    ContentFilter.safe_filter_options
  end

  def before_validation
    self.url = generate_url(:url,self.name) if self.url.blank?
  end

  def main_forums
    @forums ||= self.forum_forums.main_forums.find(:all, :order => 'forum_forums.name')
  end

  def can_add_attachments_to_posts?
    self.allow_attachments && self.upload_folder
  end

  def valid_file_size?(size)
    if self.file_size_limit && self.file_size_limit > 0
      size <= self.file_size_limit
    else
      true
    end
  end
end
