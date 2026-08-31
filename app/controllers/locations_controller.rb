class LocationsController < ApplicationController
  before_action :require_account!
  before_action :set_location, only: %i[ show edit update destroy ]

  # GET /locations or /locations.json
  def index
    @pagy, @locations = pagy(policy_scope(Location))
  end

  # GET /locations/1 or /locations/1.json
  def show
    authorize @location
    @inventory_levels = @location.inventory_levels.includes(:inventory_item)
  end

  # GET /locations/new
  def new
    @location = Location.new
    authorize @location
  end

  # GET /locations/1/edit
  def edit
    authorize @location
  end

  # POST /locations or /locations.json
  def create
    @location = Location.new(location_params)
    authorize @location

    respond_to do |format|
      if @location.save
        format.html { redirect_to @location, notice: "Location created" }
        format.json { render :show, status: :created, location: @location }
      else
        flash.now[:alert] = "Save failed"
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @location.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /locations/1 or /locations/1.json
  def update
    authorize @location
    respond_to do |format|
      if @location.update(location_params)
        format.html { redirect_to @location, notice: "Location updated", status: :see_other }
        format.json { render :show, status: :ok, location: @location }
      else
        flash.now[:alert] = "Update failed"
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @location.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /locations/1 or /locations/1.json
  def destroy
    authorize @location
    @location.destroy!

    respond_to do |format|
      format.html { redirect_to locations_path, notice: "Location deleted", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_location
      @location = Location.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def location_params
      params.require(:location).permit(:name, :collection_point)
    end
end
