
class Rewards::PageController < ParagraphController

  editor_header 'Rewards Paragraphs'

  editor_for :redeem, :name => "Redeem", :feature => :rewards_page_redeem

  class RedeemOptions < HashModel
    attributes :success_page_id => nil

    page_options :success_page_id

    options_form(
                 fld(:success_page_id, :page_selector)
                 )
  end
end
