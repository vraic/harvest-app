class TasksController < ApplicationController
  before_action :require_account!
  before_action :set_task, only: %i[ show edit update destroy complete incomplete ]

  # GET /tasks or /tasks.json
  def index
    @status = params[:status] == "completed" ? "completed" : "pending"
    tasks = if @status == "completed"
               policy_scope(Task).completed.order(completed_at: :desc)
    else
               policy_scope(Task).incomplete.order(created_at: :desc)
    end
    @pagy, @tasks = pagy(tasks)
  end

  def complete
    authorize @task
    @task.complete!
    respond_to do |format|
      format.html { redirect_back fallback_location: tasks_path, notice: "Task completed" }
      format.json { render :show, status: :ok, location: @task }
    end
  end

  def incomplete
    authorize @task, :complete?
    @task.incomplete!
    respond_to do |format|
      format.html { redirect_back fallback_location: tasks_path, notice: "Task reopened" }
      format.json { render :show, status: :ok, location: @task }
    end
  end

  # GET /tasks/1 or /tasks/1.json
  def show
    authorize @task
  end

  # GET /tasks/new
  def new
    @task = Task.new
    authorize @task
    @users = policy_scope(User).order(:name)
  end

  # GET /tasks/1/edit
  def edit
    authorize @task
    @users = policy_scope(User).order(:name)
  end

  # POST /tasks or /tasks.json
  def create
    @task = Task.new(task_params)
    @task.account ||= Current.account
    @task.assigned_by ||= Current.user
    authorize @task

    respond_to do |format|
      if @task.save
        format.html { redirect_to tasks_path, notice: "Task created" }
        format.json { render :show, status: :created, location: @task }
      else
        @users = policy_scope(User).order(:name)
        flash.now[:alert] = "Save failed"
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @task.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /tasks/1 or /tasks/1.json
  def update
    authorize @task
    respond_to do |format|
      if @task.update(task_params)
        format.html { redirect_to tasks_path, notice: "Task updated", status: :see_other }
        format.json { render :show, status: :ok, location: @task }
      else
        @users = policy_scope(User).order(:name)
        flash.now[:alert] = "Update failed"
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @task.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /tasks/1 or /tasks/1.json
  def destroy
    authorize @task
    @task.destroy!

    respond_to do |format|
      format.html { redirect_to tasks_path, notice: "Task deleted", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_task
      @task = Task.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def task_params
      params.require(:task).permit(:title, :description, :responsible_user_id, :due_date, attachments: [])
    end
end
