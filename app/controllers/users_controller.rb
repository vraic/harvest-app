class UsersController < ApplicationController
  layout "application"
  before_action :set_user, only: %i[ show edit update destroy anonymise really_destroy ]

  # GET /users or /users.json
  def index
    @pagy, @users = pagy(User.all)
  end

  # GET /users/1 or /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users or /users.json
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        @user.password = @user.password_confirmation = nil
        format.html { redirect_to @user, notice: "User created" }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @user.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /users/1 or /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        @user.password = @user.password_confirmation = nil
        format.html { redirect_to @user, notice: "User updated", status: :see_other }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @user.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /users/1 or /users/1.json
  def destroy
    if @user.admin?
      redirect_to users_path, alert: "Cannot delete admin"
      return
    end

    @user.destroy!

    respond_to do |format|
      format.html { redirect_to users_path, notice: "User archived", status: :see_other }
      format.json { head :no_content }
    end
  end

  def anonymise
    if @user.admin?
      redirect_to users_path, alert: "Cannot anonymise admin"
      return
    end

    @user.anonymise!
    @user.destroy! unless @user.deleted?

    respond_to do |format|
      format.html { redirect_to users_path, notice: "User anonymised", status: :see_other }
      format.json { head :no_content }
    end
  end

  def really_destroy
    unless Current.user.admin?
      redirect_to users_path, alert: "Admins only"
      return
    end

    if @user.admin?
      redirect_to users_path, alert: "Cannot delete admin"
      return
    end

    @user.destroy_fully!

    respond_to do |format|
      format.html { redirect_to users_path, notice: "User deleted", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(:email_address, :password, :name)
    end
end
