
class ForumAddForumWizard < HashModel

  attributes :forum_category_id => nil,
  :add_to_id => nil,
  :add_to_subpage => 'forums',
  :add_to_existing => nil,
  :forum_page_url => 'view',
  :new_page_url => 'new',
  :edit_page_url => 'edit'

  validates_format_of :add_to_subpage, :with => /^[a-zA-Z0-9\-_]+$/, :message => 'is an invalid url'
  validates_format_of :forum_page_url, :with => /^[a-zA-Z0-9\-_]+$/, :message => 'is an invalid url'
  validates_format_of :new_page_url, :with => /^[a-zA-Z0-9\-_]+$/, :message => 'is an invalid url'
  validates_format_of :edit_page_url, :with => /^[a-zA-Z0-9\-_]+$/, :message => 'is an invalid url'

  validates_presence_of :forum_category_id
  validates_presence_of :add_to_id
  validates_presence_of :forum_page_url
  validates_presence_of :new_page_url
  validates_presence_of :edit_page_url

  def validate
    if self.add_to_existing.blank? && self.add_to_subpage.blank?
      self.errors.add(:add_to," must have a subpage selected or add\n to existing must be checked")
    end
  end

  def add_to_site!
    nd = SiteNode.find(self.add_to_id)

    if self.add_to_existing.blank?
      nd = nd.add_subpage(self.add_to_subpage)
    end

    view_page = nd.add_subpage(self.forum_page_url)
    view_page.save
    
    new_page = nd.add_subpage(self.new_page_url)
    new_page.save
    
    edit_page = nd.add_subpage(self.edit_page_url)
    edit_page.save
    
    list_revision = nd.page_revisions[0]
    view_revision = view_page.page_revisions[0]
    new_revision = new_page.page_revisions[0]
    edit_revision = edit_page.page_revisions[0]

    list_para = list_revision.add_paragraph('/forum/page','list',
                                {
                                  :forum_category_id => self.forum_category_id,
                                  :forum_page_id => view_page.id
                                }
                                )
    list_para.save

    view_para = view_revision.add_paragraph('/forum/page','forum',
                                {
                                  :forum_page_id => view_page.id,
                                  :new_post_page_id => new_page.id
                                }
                                )
    view_para.add_page_input(:forum,:page_arg_0,:url)
    view_para.add_page_input(:topic,:page_arg_1,:id)
    view_para.save

    topic_para = view_revision.add_paragraph('/forum/page','topic',
                                {
                                  :forum_page_id => view_page.id,
                                  :new_post_page_id => new_page.id,
                                  :edit_post_page_id => edit_page.id
                                }
                                )
    topic_para.add_page_input(:forum,:page_arg_0,:url)
    topic_para.add_page_input(:topic,:page_arg_1,:id)
    topic_para.save

    new_para = new_revision.add_paragraph('/forum/page','new_post',
                                {
                                  :forum_page_id => view_page.id
                                }
                                )
    new_para.add_page_input(:input,:page_arg_0,:forum_path)
    new_para.add_page_input(:topic,:page_arg_1,:id)
    new_para.add_page_input(:post,:page_arg_2,:id)
    new_para.save

    edit_para = edit_revision.add_paragraph('/forum/page','edit_post',
                                {
                                  :forum_page_id => view_page.id
                                }
                                )
    edit_para.add_page_input(:forum,:page_arg_0,:url)
    edit_para.add_page_input(:topic,:page_arg_1,:id)
    edit_para.add_page_input(:post,:page_arg_2,:id)
    edit_para.save

    list_revision.make_real
    view_revision.make_real
    new_revision.make_real
    edit_revision.make_real
  end
end

