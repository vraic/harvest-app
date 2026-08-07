class ShopsController < ApplicationController
  skip_before_action :set_tenant, only: [ :show ]
  before_action :require_authentication

  def show
    account_ids = visible_account_ids
    @accounts = Account.unscoped.where(id: account_ids)
    @categories = InventoryGroup.unscoped.where(account_id: account_ids).order(:name)
    @products = InventoryItem.unscoped.where(account_id: account_ids, parent_id: nil)

    if params[:account_id].present? && account_ids.include?(params[:account_id].to_i)
      @products = @products.where(account_id: params[:account_id])
      @categories = @categories.where(account_id: params[:account_id])
    end

    if params[:min_price].present?
      @products = @products.where("price_cents >= ?", (params[:min_price].to_f * 100).to_i)
    end

    if params[:max_price].present?
      @products = @products.where("price_cents <= ?", (params[:max_price].to_f * 100).to_i)
    end

    if params[:min_quantity].present?
      @products = @products.joins(:inventory_levels).group(:id).having("SUM(inventory_levels.quantity) >= ?", params[:min_quantity].to_i)
    end

    if params[:account_id].present? || params[:min_price].present? || params[:max_price].present? || params[:min_quantity].present?
      @pagy, @products = pagy(@products)
      @show_all_results = true
    else
      @featured_products = @products.limit(8)
      @show_all_results = false
    end
  end
end
