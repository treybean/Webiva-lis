
class Notification::PageFeature < ParagraphFeature

  feature :notification_page_notifications, :default_feature => <<-FEATURE
  <cms:notifications>
    <cms:notification>
      <cms:name/> <cms:created_at/><br/>
      <cms:message>
        Customize the message...
      </cms:message>
      <cms:can_clear><cms:clear_link>[x] remove</cms:clear_link></cms:can_clear>
      <br/>
    </cms:notification>
  </cms:notifications>
  FEATURE

  def notification_page_notifications_feature(data)
    webiva_feature(:notification_page_notifications,data) do |c|
      c.value_tag('paragraph_id') { |t| "cmspara_#{paragraph.id}" }

      c.expansion_tag('logged_in') { |t| myself.id }

      c.loop_tag('notification') { |t| data[:notifications] }

      c.h_tag('notification:name') { |t|  t.locals.notification.name }
      c.date_tag('notification:created_at',DEFAULT_DATETIME_FORMAT.t) { |t|  t.locals.notification.created_at }

      c.expansion_tag('notification:can_clear') { |t| t.locals.notification.view_type == 'clear' }
      c.value_tag('notification:can_clear:clear_url') { |t| "#{self.ajax_url}?message=#{t.locals.notification.id}&clear=1" }
      c.define_tag('notification:can_clear:clear_link') { |t|
        "<a href=\"javascript:void(0);\" onclick=\"new Ajax.Updater('cmspara_#{paragraph.id}', '#{self.ajax_url}?message=#{t.locals.notification.id}&clear=1');\">" + t.expand + '</a>'
      }

      if data[:type]
        c.expansion_tag('notification:message') { |t| t.locals.entry = t.locals.notification.data_model }
        c.content_model_fields_value_tags('notification:message', data[:type].content_model.content_model_fields)
      end
    end
  end
end
