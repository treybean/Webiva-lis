
class Rewards::PageRenderer < ParagraphRenderer

  features '/rewards/page_feature'

  paragraph :redeem

  def redeem
    @options = paragraph_options :redeem

    @user = RewardsUser.push_user(myself.id) if myself.id

    cart = nil
    product = nil
    if @user
      cart = get_cart
      product = cart.products.detect { |p| p.cart_item_type == 'RewardsTransaction' }

      @rewards = product ? @user.rewards_transactions.find_by_id(product.cart_item_id) : @user.rewards_transactions.build(:transaction_type => 'debit', :amount => 0, :note => '[User redeemed]')
      @rewards.amount = product.quantity if product

      @num_real_items = cart.real_items
      @max_amount = @rewards.cart_limit({}, cart)
    end

    if request.post? && @rewards && @num_real_items > 0 && params[:rewards]
      amount = (params[:rewards][:amount] || 0).to_i

      # remove the rewards
      if product && amount == 0
        cart.edit_product @rewards, 0
        @rewards.destroy
        if @options.success_page_url
          redirect_paragraph @options.success_page_url
          return
        end
        @removed = true
      else
        @rewards.amount = amount

        if @rewards.save
          product ? cart.edit_product(@rewards, amount) : cart.add_product(@rewards, amount)
          if @options.success_page_url
            redirect_paragraph @options.success_page_url
            return
          end
          @updated = true
        end
      end
    end

    render_paragraph :feature => :rewards_page_redeem
  end

  protected

  include Shop::CartUtility # Get Cart Functionality

end
