class CartsController < ApplicationController
  skip_before_action :set_tenant, only: [ :add_item, :remove_item, :show, :destroy, :update ]
  before_action :require_authentication
  before_action :remove_inaccessible_cart_items!, only: :show

  def show
    @cart = current_cart
  end

  def update
    product = InventoryItem.unscoped.find(params[:product_id])
    return unless ensure_storefront_access!(product, fallback_location: cart_path)

    quantity = params[:quantity].to_i

    current_cart.set_quantity(product.id, quantity)

    respond_to do |format|
      format.html { redirect_to cart_path, notice: "Cart updated" }
      format.turbo_stream {
        flash.now[:notice] = "Cart updated"
        @cart = current_cart
      }
    end
  end

  def add_item
    product = InventoryItem.unscoped.find(params[:product_id])
    return unless ensure_storefront_access!(product, fallback_location: shop_path)

    quantity = params[:quantity].to_i > 0 ? params[:quantity].to_i : 1

    current_cart.add_item(product.id, quantity)

    respond_to do |format|
      format.html { redirect_back fallback_location: shop_path, notice: "Added to cart" }
      format.turbo_stream { flash.now[:notice] = "Added to cart" }
    end
  end

  def remove_item
    product = InventoryItem.unscoped.find(params[:product_id])
    return unless ensure_storefront_access!(product, fallback_location: cart_path)

    current_cart.remove_item(product.id)

    respond_to do |format|
      format.html { redirect_back fallback_location: cart_path, notice: "Removed from cart" }
      format.turbo_stream { flash.now[:notice] = "Removed from cart" }
    end
  end

  def destroy
    session[:cart] = nil
    redirect_to shop_path, notice: "Cart cleared"
  end

  private

  def remove_inaccessible_cart_items!
    removed = false

    current_cart.items.each do |item|
      next if storefront_accessible_account?(item.account)

      current_cart.remove_item(item.product.id)
      removed = true
    end

    return unless removed

    flash.now[:alert] = "Items removed"
  end

  def ensure_storefront_access!(product, fallback_location:)
    return true if storefront_accessible_account?(product.account)

    respond_to do |format|
      format.html { redirect_back fallback_location: fallback_location, alert: "Store unavailable" }
      format.turbo_stream { redirect_back fallback_location: fallback_location, alert: "Store unavailable" }
    end

    false
  end

  def current_cart
    @current_cart ||= Cart.new(session)
  end
  helper_method :current_cart
end
