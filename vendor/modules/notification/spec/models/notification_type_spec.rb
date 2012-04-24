require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"

describe NotificationType do

  reset_domain_tables :notification_type

  it "should require a name and a content model" do
    @type = NotificationType.new
    @type.should have(1).error_on(:name)
    @type.should have(1).error_on(:content_model_id)

    @type = NotificationType.create :name => 'notification', :content_model_id => 1
    @type.id.should_not be_nil
  end
end
