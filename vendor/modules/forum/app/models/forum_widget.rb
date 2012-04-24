
class ForumWidget < Dashboard::WidgetBase
  widget :topics, :name => "Forum: Display Forum Topics w/o Replies", :title => "Forum Topics w/o Replies", :permission => :forum_manage

  def topics
    set_icon 'forms_icon.png'
    @forum = ForumForum.find_by_id(options.forum_forum_id) if options.forum_forum_id
    if @forum
      set_title_link url_for(:controller => '/forum/topics', :action => 'list', :path => [@forum.forum_category_id, @forum.id])
    else
      set_title_link url_for(:controller => 'content')
    end
    scope = ForumTopic.scoped(:conditions => {:forum_posts_count => 1})
    scope = scope.scoped(:conditions => {:forum_forum_id => options.forum_forum_id}) if options.forum_forum_id
    @topics = scope.find(:all, :limit => options.limit)
    render_widget :partial => '/forum/widget/topics', :locals => {:topics => @topics , :options => options}
  end

  class TopicsOptions < HashModel
    attributes :count => 20, :forum_forum_id => nil

    integer_options :count
    validates_numericality_of :count

    def forum_forum_options
      ForumForum.select_options_with_nil
    end

    options_form(
                 fld(:forum_forum_id, :select, :options => :forum_forum_options),
                 fld(:count, :text_field, :label => "Number of topics to displayed")
                 )
  end
end
