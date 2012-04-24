# Copyright (C) 2009 Pascal Rettig.

class Forum::PageController < ParagraphController

  editor_header 'Forum Paragraphs'

  editor_for :categories, :name => 'List of Forum Categories', :feature => :forum_page_categories,
                          :inputs => [[:url, 'Category Url', :path]]

  editor_for :list, :name => "List of Forums", :feature => :forum_page_list,
                    :inputs => [[:url, 'Category Url', :path]],
                    :outputs => [[:category, 'Forum Category Target', :forum_category_target]]

  editor_for :forum, :name => "Forum Display", :feature => :forum_page_forum,
                     :inputs => { :forum => [[:url, 'Forum Url', :path]], 
                                  :topic => [[:id, 'Topic Id', :path]] },
                     :outputs => [[:forum, 'Forum Target', :forum_forum_target]]

  editor_for :topic, :name => "Forum Topic Display", :feature => :forum_page_topic,
                     :inputs => { :forum => [[:url, 'Forum Url', :path]], 
                                  :topic => [[:id, 'Topic Id', :path]] },
                     :outputs => [[:topic, 'Topic Target', :forum_topic_target]]

  editor_for :new_post, :name => "New Post Form", :feature => :forum_page_new_post,
                        :inputs => { :input => [[:forum, 'Forum', :forum_forum_target],
                                                [:topic, 'Topic', :forum_topic_target],
                                                [:forum_path, 'Forum Url', :path]],
                                     :topic => [[:id, 'Topic Id', :path]],
                                     :post => [[:id, 'Post Id', :path]],
                                     :content => [[:content, 'Content Identifier', :content]]
                                   },
                        :triggers => [['New Post','new_post'], ['New Topic','new_topic']]

  editor_for :edit_post, :name => "Edit Post Form", :feature => :forum_page_edit_post,
                        :inputs => { :forum => [[:url, 'Forum Url', :path]],
                                     :topic => [[:id, 'Topic Id', :path]],
                                     :post => [[:id, 'Post Id', :path]]
                                   }

  editor_for :recent, :name => "Recent Posts Display", :feature => :forum_page_recent,
                      :inputs => { :input => [[:category, 'Category', :forum_category_target],
                                              [:forum, 'Forum', :forum_forum_target],
                                              [:category_path, 'Forum Category Url', :path]],
                                   :forum => [[:url, 'Forum Url (only used with Forum Category Url)', :path]],
                                   :content => [[:content, 'Content Identifier', :content]]
                                 }

  class CategoriesOptions < HashModel
    attributes :categories_per_page => 20, :category_page_id => nil, :forum_page_id => nil

    integer_options :categories_per_page

    page_options :category_page_id
    page_options :forum_page_id

    options_form(
                 fld(:categories_per_page, :text_field),
                 fld(:category_page_id, :page_selector),
                 fld(:forum_page_id, :page_selector)
                 )
  end

  class ListOptions < HashModel
    attributes :forum_category_id => nil, :forums_per_page => 10, :category_page_id => nil, :forum_page_id => nil

    integer_options :forums_per_page

    page_options :category_page_id
    page_options :forum_page_id

    options_form(
                 fld(:forum_category_id, :select, :options => :forum_category_options),
                 fld(:forums_per_page, :text_field),
                 fld(:category_page_id, :page_selector),
                 fld(:forum_page_id, :page_selector)
                 )

    def self.forum_category_options
      [['Use page connection', nil]] + ForumCategory.select_options
    end
  end

  class ForumOptions < HashModel
    attributes :forum_forum_id => nil, :topics_per_page => 20, :category_page_id => nil, :forum_page_id => nil, :new_post_page_id => nil

    integer_options :topics_per_page

    page_options :category_page_id
    page_options :forum_page_id
    page_options :new_post_page_id

   options_form(
                 fld(:forum_forum_id, :select, :options => :forum_forum_options),
                 fld(:topics_per_page, :text_field),
                 fld(:category_page_id, :page_selector),
                 fld(:forum_page_id, :page_selector),
                 fld(:new_post_page_id, :page_selector)
                 )

    def self.forum_forum_options
      [['Use page connection', nil]] + ForumForum.select_options
    end
  end

  class TopicOptions < HashModel
    attributes :forum_forum_id => nil, :posts_per_page => 20, :category_page_id => nil, :forum_page_id => nil, :new_post_page_id => nil, :edit_post_page_id => nil

    integer_options :posts_per_page

    page_options :category_page_id
    page_options :forum_page_id
    page_options :new_post_page_id
    page_options :edit_post_page_id

    meta_canonical_paragraph "ForumForum", :list_page_id => :forum_page_id, :url_field => :url 

   options_form(
                 fld(:forum_forum_id, :select, :options => :forum_forum_options),
                 fld(:posts_per_page, :text_field),
                 fld(:category_page_id, :page_selector),
                 fld(:forum_page_id, :page_selector),
                 fld(:new_post_page_id, :page_selector),
                 fld(:edit_post_page_id, :page_selector)
                 )

    def self.forum_forum_options
      [['Use page connection', nil]] + ForumForum.select_options
    end
  end

  class NewPostOptions < HashModel
    attributes :forum_forum_id => nil, :posts_per_page => 20, :category_page_id => nil, :forum_page_id => nil

    integer_options :posts_per_page

    page_options :category_page_id
    page_options :forum_page_id

    options_form(
                 fld(:forum_forum_id, :select, :options => :forum_forum_options),
                 fld(:posts_per_page, :text_field),
                 fld(:category_page_id, :page_selector),
                 fld(:forum_page_id, :page_selector)
                 )

    def self.forum_forum_options
      [['Use page connection', nil]] + ForumForum.select_options
    end

    def options_partial
      "/application/triggered_options_partial"
    end
  end

  class EditPostOptions < HashModel
    attributes :forum_page_id => nil

    page_options :forum_page_id

    validates_presence_of :forum_page_id

    options_form(
                 fld(:forum_page_id, :page_selector)
                 )
  end

  class RecentOptions < HashModel
    attributes :forum_category_id => -1, :forum_forum_id => nil, :topics_per_page => 20, :category_page_id => nil, :forum_page_id => nil

    integer_options :topics_per_page

    page_options :category_page_id
    page_options :forum_page_id

    options_form(
                 fld(:forum_category_id, :select, :options => :forum_category_options),
                 fld(:forum_forum_id, :select, :options => :forum_forum_options),
                 fld(:topics_per_page, :text_field),
                 fld(:category_page_id, :page_selector),
                 fld(:forum_page_id, :page_selector)
                 )

    def self.forum_category_options
      [['Use page connection', nil]] + ForumCategory.select_options
    end

    def self.forum_forum_options
      [['Use page connection', nil]] + ForumForum.select_options
    end
  end

end
