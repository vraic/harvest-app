class Shop::CategoriesController < ApplicationController
  skip_before_action :set_tenant, only: [ :show ]
  before_action :require_authentication

  def show
    @category = InventoryGroup.unscoped.where(account_id: visible_account_ids).find(params[:id])
    @products = InventoryItem.unscoped.where(inventory_group: @category, parent_id: nil)

    if params[:min_price].present?
      @products = @products.where("price_cents >= ?", (params[:min_price].to_f * 100).to_i)
    end

    if params[:max_price].present?
      @products = @products.where("price_cents <= ?", (params[:max_price].to_f * 100).to_i)
    end

    if params[:min_quantity].present?
      @products = @products.joins(:inventory_levels).group(:id).having("SUM(inventory_levels.quantity) >= ?", params[:min_quantity].to_i)
    end

    @pagy, @products = pagy(@products)
  end
end
