class NotificationsController < ApplicationController
  before_action :require_account!
  before_action :ensure_staff_access!

  def index
    @notifications = current_user.notifications
      .includes(:event)
      .for_account(Current.account)
      .order(created_at: :desc)
  end

  private

  def ensure_staff_access!
    redirect_to shop_path, alert: "Access denied" unless staff?
  end
end
