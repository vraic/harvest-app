class SupplierPricesController < ApplicationController
  before_action :require_account!
  before_action :set_inventory_item

  def create
    @supplier_price = @inventory_item.supplier_prices.new(supplier_price_params)
    authorize @supplier_price

    if @supplier_price.save
      redirect_to @inventory_item, notice: "Price set"
    else
      redirect_to @inventory_item, alert: "Save failed"
    end
  end

  def destroy
    @supplier_price = @inventory_item.supplier_prices.find(params[:id])
    authorize @supplier_price
    @supplier_price.destroy!
    redirect_to @inventory_item, notice: "Price removed", status: :see_other
  end

  private

  def set_inventory_item
    @inventory_item = InventoryItem.find(params[:inventory_item_id])
  end

  def supplier_price_params
    params.require(:supplier_price).permit(:supplier_id, :price)
  end
end
