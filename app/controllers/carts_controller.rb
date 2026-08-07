class CartsController < ApplicationController
  skip_before_action :set_tenant, only: [ :add_item, :remove_item, :show, :destroy, :update ]
  before_action :require_authentication

  def show
    @cart = current_cart
  end

  def update
    product = InventoryItem.unscoped.find(params[:product_id])
    quantity = params[:quantity].to_i

    current_cart.set_quantity(product.id, quantity)

    respond_to do |format|
      format.html { redirect_to cart_path, notice: "Cart updated." }
      format.turbo_stream {
        flash.now[:notice] = "Cart updated."
        @cart = current_cart
      }
    end
  end

  def add_item
    product = InventoryItem.unscoped.find(params[:product_id])
    quantity = params[:quantity].to_i > 0 ? params[:quantity].to_i : 1

    current_cart.add_item(product.id, quantity)

    respond_to do |format|
      format.html { redirect_back fallback_location: shop_path, notice: "#{product.name} added to cart." }
      format.turbo_stream { flash.now[:notice] = "#{product.name} added to cart." }
    end
  end

  def remove_item
    product = InventoryItem.unscoped.find(params[:product_id])
    current_cart.remove_item(product.id)

    respond_to do |format|
      format.html { redirect_back fallback_location: cart_path, notice: "#{product.name} removed from cart." }
      format.turbo_stream { flash.now[:notice] = "#{product.name} removed from cart." }
    end
  end

  def destroy
    session[:cart] = nil
    redirect_to shop_path, notice: "Cart cleared."
  end

  private

  def current_cart
    @current_cart ||= Cart.new(session)
  end
  helper_method :current_cart
end
