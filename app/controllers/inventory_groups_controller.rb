class InventoryGroupsController < ApplicationController
  before_action :require_account!
  before_action :set_inventory_group, only: %i[ show edit update destroy ]

  # GET /inventory_groups or /inventory_groups.json
  def index
    @pagy, @inventory_groups = pagy(policy_scope(InventoryGroup))
  end

  # GET /inventory_groups/1 or /inventory_groups/1.json
  def show
    authorize @inventory_group
    @inventory_items = @inventory_group.inventory_items.where(parent_id: nil)
  end

  # GET /inventory_groups/new
  def new
    @inventory_group = InventoryGroup.new
    authorize @inventory_group
  end

  # GET /inventory_groups/1/edit
  def edit
    authorize @inventory_group
  end

  # POST /inventory_groups or /inventory_groups.json
  def create
    @inventory_group = InventoryGroup.new(inventory_group_params)
    authorize @inventory_group

    respond_to do |format|
      if @inventory_group.save
        format.html { redirect_to @inventory_group, notice: "Group created" }
        format.json { render :show, status: :created, location: @inventory_group }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @inventory_group.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /inventory_groups/1 or /inventory_groups/1.json
  def update
    authorize @inventory_group
    respond_to do |format|
      if @inventory_group.update(inventory_group_params)
        format.html { redirect_to @inventory_group, notice: "Group updated", status: :see_other }
        format.json { render :show, status: :ok, location: @inventory_group }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @inventory_group.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /inventory_groups/1 or /inventory_groups/1.json
  def destroy
    authorize @inventory_group
    @inventory_group.destroy!

    respond_to do |format|
      format.html { redirect_to inventory_groups_path, notice: "Group deleted", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_inventory_group
      @inventory_group = InventoryGroup.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def inventory_group_params
      params.require(:inventory_group).permit(:name, supplier_ids: [], customer_ids: [])
    end
end
