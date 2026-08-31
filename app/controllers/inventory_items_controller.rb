class InventoryItemsController < ApplicationController
  before_action :require_account!
  before_action :set_inventory_item, only: %i[ show edit update destroy really_destroy ]

  # GET /inventory_items or /inventory_items.json
  def index
    @query = params[:query]
    @inventory_items = policy_scope(InventoryItem).where(parent_id: nil)

    if @query.present?
      # SearchCop handles numeric searches better if numbers and units are separated by a space
      search_query = @query.gsub(/(?<=\d)(?=[a-zA-Z])|(?<=[a-zA-Z])(?=\d)/, " ")
      # Search all items and find their parents or themselves if they are parents
      matched_ids = policy_scope(InventoryItem).search(search_query).pluck(:parent_id, :id).flatten.compact.uniq
      @inventory_items = @inventory_items.where(id: matched_ids)
    end

    if params[:location_id].present?
      # Find items (or their variants) that are in the specified location
      item_ids = InventoryLevel.where(location_id: params[:location_id]).pluck(:inventory_item_id)
      # We want to show the parent items
      parent_ids = InventoryItem.where(id: item_ids).pluck(:parent_id, :id).flatten.compact.uniq
      @inventory_items = @inventory_items.where(id: parent_ids)
    end

    if params[:inventory_group_id].present?
      @inventory_items = @inventory_items.where(inventory_group_id: params[:inventory_group_id])
    end

    @pagy, @inventory_items = pagy(@inventory_items)

    @locations = policy_scope(Location)
    @inventory_groups = policy_scope(InventoryGroup)
  end

  # GET /inventory_items/1 or /inventory_items/1.json
  def show
    authorize @inventory_item
    @variants = @inventory_item.variants
    @inventory_levels = @inventory_item.inventory_levels.includes(:location)
    @locations = policy_scope(Location)
  end

  # GET /inventory_items/new
  def new
    @inventory_item = InventoryItem.new(parent_id: params[:parent_id])
    authorize @inventory_item
  end

  # GET /inventory_items/1/edit
  def edit
    authorize @inventory_item
  end

  # POST /inventory_items or /inventory_items.json
  def create
    @inventory_item = InventoryItem.new(inventory_item_params)
    @inventory_item.account ||= Current.account
    authorize @inventory_item

    respond_to do |format|
      if @inventory_item.save
        format.html { redirect_to @inventory_item.parent || @inventory_item, notice: "Item created" }
        format.json { render :show, status: :created, location: @inventory_item }
      else
        flash.now[:alert] = "Save failed"
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @inventory_item.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /inventory_items/1 or /inventory_items/1.json
  def update
    authorize @inventory_item
    respond_to do |format|
      if @inventory_item.update(inventory_item_params)
        format.html { redirect_to @inventory_item.parent || @inventory_item, notice: "Item updated", status: :see_other }
        format.json { render :show, status: :ok, location: @inventory_item }
      else
        flash.now[:alert] = "Update failed"
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @inventory_item.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /inventory_items/1 or /inventory_items/1.json
  def destroy
    authorize @inventory_item
    parent = @inventory_item.parent
    @inventory_item.destroy!

    respond_to do |format|
      format.html { redirect_to parent || inventory_items_path, notice: "Item deleted", status: :see_other }
      format.json { head :no_content }
    end
  end

  def really_destroy
    authorize @inventory_item
    parent = @inventory_item.parent
    @inventory_item.destroy_fully!

    respond_to do |format|
      format.html { redirect_to parent || inventory_items_path, notice: "Item permanently deleted", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_inventory_item
      @inventory_item = InventoryItem.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def inventory_item_params
      params.require(:inventory_item).permit(:name, :description, :price, :inventory_group_id, :parent_id, :unit_type, :weight_value, :weight_unit, :warn_when_low_on_stock, :low_stock_threshold)
    end
end
