class Shop::ProductsController < ApplicationController
  skip_before_action :set_tenant, only: [ :show ]
  before_action :require_authentication

  def show
    @product = InventoryItem.unscoped.where(account_id: visible_account_ids).find(params[:id])
    @variants = @product.variants
  end
end
