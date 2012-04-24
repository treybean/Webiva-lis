class Rewards::PageFeature < ParagraphFeature

  feature :rewards_page_redeem, :default_feature => <<-FEATURE
  <cms:rewards>
    <div>
     You have <cms:rewards_amount/> rewards. You can redeem up to <cms:max_amount/> rewards.
    </div>
    <cms:redeemable>
    <cms:cart_items>
      <cms:form>
      <ul>
        <li><cms:amount_label/><cms:amount/></li>
        <li><cms:submit/></li>
      </ul>
      </cms:form>
    </cms:cart_items>
    </cms:redeemable>
    <cms:not_redeemable>
      <p>You must have at least <cms:rewards_value/> rewards in order to redeem them.</p>
    </cms:not_redeemable>
    <cms:no_cart_items>
      <p>There are no items in your cart. You must have items in your cart to redeem rewards.</p>
    </cms:no_cart_items>
  </cms:rewards>
  <cms:no_rewards>
    <p>You must be logged in to redeem your rewards.</p>
  </cms:no_rewards>
  FEATURE

  def rewards_page_redeem_feature(data)
    webiva_feature(:rewards_page_redeem,data) do |c|
      c.expansion_tag('logged_in') { |t| data[:user] }
      c.expansion_tag('rewards') { |t| t.locals.user = data[:user] }
      c.value_tag('rewards:rewards_amount') { |t| t.locals.user.rewards }
      c.value_tag('rewards:dollar_amount') { |t| t.locals.user.dollar_amount }
      c.value_tag('rewards:rewards_value') { |t| t.locals.user.rewards_value }
      c.value_tag('rewards:max_amount') { |t| data[:max_amount] }
      c.expansion_tag('rewards:redeemable') { |t| t.locals.user.rewards >= t.locals.user.rewards_value }

      c.form_for_tag('rewards:form','rewards') { |t| t.locals.rewards = data[:rewards] }
        c.field_tag('rewards:form:amount')
        c.button_tag('rewards:form:submit')

      c.expansion_tag('rewards:form:updated') { |t| data[:updated] }
      c.expansion_tag('rewards:form:removed') { |t| data[:removed] }
      c.expansion_tag('rewards:cart_items') { |t| data[:num_real_items].to_i > 0 }
    end
  end

end
