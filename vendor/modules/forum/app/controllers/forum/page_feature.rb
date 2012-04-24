# Copyright (C) 2009 Pascal Rettig.

class Forum::PageFeature < ParagraphFeature

  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::NumberHelper

  feature :forum_page_categories,
    :default_css_file => '/components/forum/stylesheets/forum.css',
    :default_feature => <<-FEATURE
    <cms:categories>
      <div class="webiva_forum">
      <cms:category>
        <div class="category_name"><cms:name/></div>
        <cms:forums>
          <cms:forum>
            <div class="forum">
              <div class="forum_name"><cms:forum_link><cms:name/></cms:forum_link></div>
              <cms:description><div class="forum_description"><cms:value/></div></cms:description>
            </div>
          </cms:forum>
        </cms:forums>
        <cms:not_last><hr class="separator"/></cms:not_last>
      </cms:category>
      </div>
    </cms:categories>
  FEATURE

  def forum_page_categories_feature(data)
    webiva_feature(:forum_page_categories) do |c|
      c.loop_tag('category') { |t| data[:categories] }
        add_category_features(c, data)
          c.loop_tag('category:forum') { |t| t.locals.category.main_forums }
            add_forum_features(c, data, 'category:forum')
    end
  end

  feature :forum_page_list,
    :default_css_file => '/components/forum/stylesheets/forum.css',
    :default_feature => <<-FEATURE
    <cms:category>
      <div class="webiva_forum">
        <div class="category_name"><cms:name/></div>
        <cms:forums>
          <cms:forum>
            <div class="forum">
              <div class="forum_name"><cms:forum_link><cms:name/></cms:forum_link></div>
              <cms:description><div class="forum_description"><cms:value/></div></cms:description>
            </div>
          </cms:forum>
          <cms:pages><div class="pages"><cms:value/></div></cms:pages>
        </cms:forums>
      </div>
    </cms:category>
  FEATURE
  
  def forum_page_list_feature(data)
    webiva_feature(:forum_page_list) do |c|
      c.define_tag('category') do |t|
	t.locals.category = data[:category]
	data[:category] ? t.expand : nil
      end

      add_category_features(c, data)

      c.loop_tag('forum') { |t| data[:forums] }
        add_forum_features(c, data)

      c.pagelist_tag('pages', :field => 'forum_page' ) { |t| data[:pages] }
    end
  end

  feature :forum_page_forum,
    :default_css_file => '/components/forum/stylesheets/forum.css',
    :default_feature => <<-FEATURE
    <cms:category>
      <div class="webiva_forum">
      <cms:forum>
        <div class="forum">
          <div class="forum_name"><cms:forum_link><cms:name/></cms:forum_link></div>
          <cms:description><div class="forum_description"><cms:value/></div></cms:description>
          <div class="new_topic"><span class="button"><cms:new_topic_link>New Thread</cms:new_topic_link></span></div>
        </div>

        <cms:topics>
          <cms:pages/>
          <div class="forum_topics">
          <table>
            <tr>
              <th class="subject">Threads</th>
              <th class="replies">Replies</th>
              <th class="created">Created</th>
            </tr>
          <cms:topic>
            <tr>
              <td class="subject">
                <cms:topic_link><cms:subject/></cms:topic_link>, <span>by <cms:posted_by/></span>
              </td>
              <td class="replies">
                <cms:replies/>
              </td>
              <td class="created">
                <cms:created_ago/> ago
              </td>
            </tr>
          </cms:topic>
          </table>
          </div>
          <cms:pages/>
        </cms:topics>
      </cms:forum>
      </div>
    </cms:category>
  FEATURE
  
  def forum_page_forum_feature(data)
    webiva_feature(:forum_page_forum) do |c|
      c.expansion_tag('category') { |t| t.locals.category = data[:forum].forum_category }

      add_category_features(c, data)

      c.expansion_tag('forum') { |t| t.locals.forum = data[:forum] }

      add_forum_features(c, data)

      c.loop_tag('forum:topic') { |t| data[:topics] }
        add_topic_features(c, data, 'forum:topic')

      c.pagelist_tag('pages', :field => 'forum_page' ) { |t| data[:pages] }
    end
  end

  feature :forum_page_topic,
    :default_css_file => '/components/forum/stylesheets/forum.css',
    :default_feature => <<-FEATURE
    <cms:category>
      <div class="webiva_forum">
      <cms:forum>
        <div class="forum">
          <div class="forum_name"><cms:forum_link><cms:name/></cms:forum_link></div>
        </div>

        <cms:topic>
          <div class="forum_topic">
            <div class="topic_subject"><cms:topic_link><cms:subject/></cms:topic_link></div>
            <cms:subscription><div class="subscription"><cms:form/></div></cms:subscription>
          </div>

          <cms:posts>
            <div class="forum_posts">
              <div class="pages"><cms:pages/></div>
              <cms:post>
                <div class="forum_post">
                  <span class="user_icon"><cms:user><cms:img size="thumb"/></cms:user></span>
                  <span class="post_content">
                    <span class="by"><cms:posted_by/></span> <div class="date"><cms:posted_at format="%e.%b.%Y %l:%M%P"/></div>
                    <div class="body"><cms:body/></div>
                  </span>
                  <cms:attachment><div class="attachment">Attachment: <cms:attachment_link><cms:name/></cms:attachment_link></div></cms:attachment>
                  <div class="actions">
                    <cms:edited><div class="edited">Modified on <span><cms:edited_at/></span></div></cms:edited>
                    <cms:edit><span class="button"><cms:edit_link>Edit</cms:edit_link></span></cms:edit>
                    <cms:reply><span class="button"><cms:reply_link>Reply</cms:reply_link></span></cms:reply>
                  </div>
                </div>
                <hr class="separator"/>
              </cms:post>
              <div class="pages"><cms:pages/></div>
            </div>
          </cms:posts>
        </cms:topic>
      </cms:forum>
      </div>
    </cms:category>
  FEATURE
  
  def forum_page_topic_feature(data)
    webiva_feature(:forum_page_topic) do |c|
      c.expansion_tag('category') { |t| t.locals.category = data[:forum].forum_category }
      add_category_features(c, data)

      c.expansion_tag('forum') { |t| t.locals.forum = data[:forum] }
      add_forum_features(c, data)

      c.expansion_tag('forum:topic') { |t| t.locals.topic = data[:topic] }
      add_topic_features(c, data, 'forum:topic')

      c.expansion_tag('forum:topic:subscription') { |t| t.locals.subscription = data[:subscription] }
      c.define_tag('forum:topic:subscription:form') do |t|
        if t.single?
          label = t.attr['label'] || "Subscribe to topic"
        else
          label = t.expand
        end

        confirm_message =  t.locals.subscription.subscribed? ? (t.attr['unsubscribe_message'] || 'Are you sure you want to unsubscribe from topic?') : (t.attr['subscribe_message'] || 'Subscribe to topic?' )

        form_tag("") +
          tag(:label,:for => 'subscribe') +
          tag(:input,:type => 'hidden', :name => 'subscribe',:value => '') + 
          tag(:input,:type => 'checkbox',
              :id => 'subscribe',
              :checked => t.locals.subscription.subscribed?,
              :name => 'subscribe',
              :onclick => "if(confirm('#{jvh confirm_message}')) { this.form.submit(); return true; } else { return false; }") + " " + h(label) + "</form>"
      end

      c.loop_tag('forum:topic:post') { |t| data[:posts] }
        add_post_features(c, data, 'forum:topic:post')

      c.pagelist_tag('pages', :field => 'posts_page' ) { |t| data[:pages] }
    end
  end

  feature :forum_page_new_post,
    :default_css_file => '/components/forum/stylesheets/forum.css',
    :default_feature => <<-FEATURE
    <div class="webiva_forum">
      <cms:forum>
        <div class="forum">
          <div class="forum_name"><cms:forum_link><cms:name/></cms:forum_link></div>
          <cms:description><div class="forum_description"><cms:value/></div></cms:description>
        </div>
      </cms:forum>
      <cms:topic>
        <div class="forum_topic">
          <div class="topic_subject"><cms:topic_link><cms:subject/></cms:topic_link></div>
        </div>
        <cms:reply_to_post>
          <div class="forum_post reply_to_post">
            <span class="user_icon"><cms:user><cms:img size="thumb"/></cms:user></span>
            <span class="post_content">
              <span class="by"><cms:posted_by/></span> <div class="date"><cms:posted_at format="%e.%b.%Y %l:%M%P"/></div>
              <div class="body"><cms:body/></div>
            </span>
            <br class="clear"/>
          </div>
        </cms:reply_to_post>
      </cms:topic>
      <div class="new_post">
      <fieldset>
      <cms:no_topic><legend>Start a new Topic</legend></cms:no_topic>
      <cms:topic><legend>Reply to Post</legend></cms:topic>
      <ul>
        <cms:post_form>
          <cms:new_post>
              <cms:errors><li class='errors'><cms:value/></li></cms:errors>
              <cms:no_name>Posted By:<br/><cms:posted_by/><br/></cms:no_name>
              <li><cms:subject_label/>
              <cms:subject/></li>
              <li><cms:body_label/>
              <cms:body/></li>
              <cms:attachment>
                <li><cms:file_label>Attachment</cms:file_label>
                <cms:file/></li>
              </cms:attachment>
              <cms:subscribe>
                <li><label>&nbsp;</label>
                <cms:field/></li>
              </cms:subscribe>
              <li><cms:tag_names_label>Tags</cms:tag_names_label>
              <cms:tag_names rows="2"/></li>
              <li><label>&nbsp;</label>
              <cms:submit/></li>
          </cms:new_post>
        </cms:post_form>
        <cms:no_post_form>
          <li class='errors'>Must be logged in to post.</li>
        </cms:no_post_form>
      </ul>
      </fieldset>
      </div>
    </div>
  FEATURE
  
  def forum_page_new_post_feature(data)
    webiva_feature(:forum_page_new_post) do |c|
      c.expansion_tag('category') { |t| t.locals.category = data[:forum].forum_category }
        add_category_features(c, data)

      c.expansion_tag('forum') { |t| t.locals.forum = data[:forum] }
        add_forum_features(c, data)

      c.expansion_tag('topic') { |t| data[:topic] ? t.locals.topic = data[:topic] : nil }
        add_topic_features(c, data)

      c.expansion_tag('post_form') { |t| data[:post] ? t.locals.post = data[:post] : nil }

      c.form_for_tag('post_form:new_post','post', :html => {:multipart => true}) { |t| t.locals.post = data[:post] }
        c.form_error_tag('post_form:new_post:errors')
        c.expansion_tag('post_form:new_post:no_name') { |t| myself.missing_name? }
        c.field_tag('post_form:new_post:posted_by')
        c.field_tag('post_form:new_post:subject')
        c.field_tag('post_form:new_post:body', :control => 'text_area', :rows => 6, :cols => 50)
        c.field_tag('post_form:new_post:tag_names', :control => 'text_area', :rows => 2, :cols => 50)
        c.expansion_tag('post_form:new_post:attachment') { |t| t.locals.post.can_add_attachments? }
          c.field_tag('post_form:new_post:attachment:file', :field => 'attachment_id', :control => 'upload_document')
        c.expansion_tag('post_form:new_post:subscribe') { |t| Forum::AdminController.module_options.subscription_template_id }
          c.field_tag('post_form:new_post:subscribe:field', :field => 'subscribe', :control => 'check_boxes', :single => true, :options => [['Subscribe to topic'.t, true]])
        c.button_tag('post_form:new_post:submit')

      c.expansion_tag('topic:reply_to_post') { |t| t.locals.post = data[:reply_to_post] }
        add_post_features(c, data, 'topic:reply_to_post')
    end
  end

  feature :forum_page_edit_post,
    :default_css_file => '/components/forum/stylesheets/forum.css',
    :default_feature => <<-FEATURE
    <div class="webiva_forum">
      <cms:forum>
        <div class="forum">
          <div class="forum_name"><cms:forum_link><cms:name/></cms:forum_link></div>
          <cms:description><div class="forum_description"><cms:value/></div></cms:description>
        </div>
      </cms:forum>
      <cms:topic>
        <div class="forum_topic">
          <div class="topic_subject"><cms:topic_link><cms:subject/></cms:topic_link></div>
        </div>
      </cms:topic>
      <div class="new_post">
      <fieldset>
      <cms:topic><legend>Edit Your Post</legend></cms:topic>
      <ul>
        <cms:post_form>
          <cms:errors><li class='errors'><cms:value/></li></cms:errors>
          <li><cms:body_label/>
          <cms:body/></li>
          <cms:attachment>
            <li><cms:file_label>Attachment</cms:file_label>
            <cms:file/></li>
          </cms:attachment>
          <li><label>&nbsp;</label>
          <cms:submit/></li>
        </cms:post_form>
      </ul>
      </fieldset>
      </div>
    </div>
  FEATURE
  
  def forum_page_edit_post_feature(data)
    webiva_feature(:forum_page_edit_post) do |c|
      c.expansion_tag('category') { |t| t.locals.category = data[:forum].forum_category }
        add_category_features(c, data)

      c.expansion_tag('forum') { |t| t.locals.forum = data[:forum] }
        add_forum_features(c, data)

      c.expansion_tag('topic') { |t| t.locals.topic = data[:topic] }
        add_topic_features(c, data)

      c.form_for_tag('post_form','post', :html => {:multipart => true}) { |t| t.locals.post = data[:post] }
        c.form_error_tag('post_form:errors')
        c.field_tag('post_form:body', :control => 'text_area', :rows => 6, :cols => 50)
        c.expansion_tag('post_form:attachment') { |t| t.locals.post.can_add_attachments? }
          c.field_tag('post_form:attachment:file', :field => 'attachment_id', :control => 'upload_document')
        c.submit_tag('post_form:submit', :default => 'Submit')
    end
  end

  feature :forum_page_recent,
    :default_css_file => '/components/forum/stylesheets/forum.css',
    :default_feature => <<-FEATURE
    <div class="webiva_forum">
      <div class="forum_topics recent_topics">
        <div class="new_topics_heading">NEW ON THE FORUM</div>
        <cms:topics>
          <cms:topic>
            <div class="topic_subject"><cms:topic_link><cms:subject/></cms:topic_link></div>
          </cms:topic>
        </cms:topics>
      </div>
    </div>
  FEATURE
  
  def forum_page_recent_feature(data)
    webiva_feature(:forum_page_recent) do |c|
      c.expansion_tag('category') { |t| t.locals.category = data[:category] }

      add_category_features(c, data)

      c.expansion_tag('forum') { |t| t.locals.forum = data[:forum] }

      add_forum_features(c, data)

      c.loop_tag('topic') { |t| data[:topics] }
        add_topic_features(c, data)

      c.pagelist_tag('pages', :field => 'forum_page' ) { |t| data[:pages] }
    end
  end

  def add_category_features(context, data, base='category')
    context.h_tag(base + ':name') { |t| t.locals.category.name }
    context.link_tag(base + ':category') { |t| "#{data[:options].category_page_url}/#{t.locals.category.url}" }
  end

  def add_forum_features(context, data, base='forum')
    context.h_tag(base + ':name') { |t| t.locals.forum.name }
    context.h_tag(base + ':description') { |t| t.locals.forum.description }
    context.image_tag(base + ':image') { |t| t.locals.forum.image }
    context.link_tag(base + ':forum') { |t| "#{data[:options].forum_page_url}/#{t.locals.forum.url}" }
    context.datetime_tag(base + ':updated_at') { |t| t.locals.forum.updated_at }
    context.value_tag(base + ':updated_ago') { |t| time_ago_in_words(t.locals.forum.updated_at) }
    context.datetime_tag(base + ':created_at') { |t| t.locals.forum.created_at }
    context.value_tag(base + ':created_ago') { |t| time_ago_in_words(t.locals.forum.created_at) }
    context.value_tag(base + ':topics_count') { |t| number_with_delimiter(t.locals.forum.forum_topics_count) }
    context.value_tag(base + ':topics_count_topics') { |t| pluralize(t.locals.forum.forum_topics_count, 'topic') }
    context.expansion_tag(base + ':on_main_page') { |t| t.locals.forum.main_page }

    if data[:options] && data[:options].new_post_page_id && ! data[:options].new_post_page_id.blank?
      context.link_tag(base + ':new_topic') { |t| "#{data[:options].new_post_page_url}/#{t.locals.forum.url}" }
    end
  end

  def add_topic_features(context, data, base='topic')
    context.h_tag(base + ':subject') { |t| truncate(t.locals.topic.subject, :length => (t.attr['length'] || 100).to_i) }
    context.h_tag(base + ':tags') { |t| t.locals.topic.tag_names || '' }
    context.h_tag(base + ':posted_by') { |t| t.locals.topic.posted_by }
    context.link_tag(base + ':topic') { |t| "#{data[:options].forum_page_url}/#{t.locals.topic.forum_forum.url}/#{t.locals.topic.url}" }
    context.value_tag(base + ':posts_count') { |t| number_with_delimiter(t.locals.topic.forum_posts_count) }
    context.value_tag(base + ':replies') { |t| number_with_delimiter(t.locals.topic.forum_posts_count-1) }
    context.value_tag(base + ':activity_count') { |t| number_with_delimiter(t.locals.topic.activity_count) }
    context.value_tag(base + ':posts_count_posts') { |t| pluralize(t.locals.topic.forum_posts_count, 'post') }
    context.value_tag(base + ':activity_count_posts') { |t| pluralize(t.locals.topic.activity_count, 'post') }
    context.value_tag(base + ':views') { |t| number_with_delimiter(t.locals.topic.views) }
    context.value_tag(base + ':views_views') { |t| pluralize(t.locals.topic.views, 'view') }
    context.datetime_tag(base + ':updated_at') { |t| t.locals.topic.updated_at }
    context.value_tag(base + ':updated_ago') { |t| time_ago_in_words(t.locals.topic.updated_at) }
    context.datetime_tag(base + ':created_at') { |t| t.locals.topic.created_at }
    context.value_tag(base + ':created_ago') { |t| time_ago_in_words(t.locals.topic.created_at) }
    context.expansion_tag(base + ':sticky') { |t| t.locals.topic.sticky > 0 }

    if data[:options] && data[:options].new_post_page_id && ! data[:options].new_post_page_id.blank?
      context.link_tag(base + ':new_post') { |t| "#{data[:options].new_post_page_url}/#{t.locals.forum.url}/#{t.locals.topic.url}" }
    end

    context.define_user_tags(base + ':user') { |t| t.locals.user = t.locals.topic.end_user }

    context.expansion_tag(base + ':first_post') { |t| t.locals.post = t.locals.topic.first_post }
      add_post_features(context, data, base + ':first_post')

    context.expansion_tag(base + ':last_post') { |t| t.locals.post = t.locals.topic.last_post }
      add_post_features(context, data, base + ':last_post')
  end

  def add_post_features(context, data, base='post')
    context.h_tag(base + ':subject') { |t| t.locals.post.subject }
    context.h_tag(base + ':posted_by') { |t| t.locals.post.posted_by }
    context.value_tag(base + ':body') { |t| t.locals.post.body_html }
    context.expansion_tag(base + ':first_post') { |t| t.locals.post.first_post }

    context.expansion_tag(base + ':attachment') { |t| t.locals.attachment = t.locals.post.attachment }
      add_attachment_features(context, data, base + ':attachment')

    context.expansion_tag(base + ':edited') { |t| t.locals.post.edited_at }
    context.datetime_tag(base + ':edited_at') { |t| t.locals.post.edited_at }
    context.value_tag(base + ':edited_ago') { |t| time_ago_in_words(t.locals.post.edited_at) }
    context.datetime_tag(base + ':posted_at') { |t| t.locals.post.posted_at }
    context.value_tag(base + ':posted_ago') { |t| time_ago_in_words(t.locals.post.posted_at) }

    context.define_user_tags(base + ':user') { |t| t.locals.user = t.locals.post.end_user }

    context.expansion_tag(base + ':reply') { |t| data[:options] && data[:options].new_post_page_url }
    context.link_tag(base + ':reply:reply') { |t| "#{data[:options].new_post_page_url}/#{t.locals.post.forum_forum.url}/#{t.locals.post.forum_topic.url}/#{t.locals.post.id}" }

    context.expansion_tag(base + ':edit') { |t| myself.id == t.locals.post.end_user_id && ! t.locals.post.end_user_id.nil? && data[:options] && data[:options].edit_post_page_url }
    context.link_tag(base + ':edit:edit') { |t| "#{data[:options].edit_post_page_url}/#{t.locals.post.forum_forum.url}/#{t.locals.post.forum_topic.url}/#{t.locals.post.id}" }
  end

  def add_attachment_features(context, data, base='attachment')
    context.h_tag(base + ':name') { |t| t.locals.attachment.name }
    context.image_tag(base + ':image') { |t| t.locals.attachment.image? ? t.locals.attachment : nil }
    context.link_tag(base + ':attachment') { |t| t.locals.attachment.full_url }
    context.value_tag(base + ':url') { |t| t.locals.attachment.full_url }
    context.value_tag(base + ':thumbnail_url') { |t| t.locals.attachment.thumbnail_url('standard', :icon) }
  end
end
