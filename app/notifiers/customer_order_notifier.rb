class CustomerOrderNotifier < ApplicationNotifier
  def message
    "New customer order: ##{record.number}"
  end

  def target_path
    Rails.application.routes.url_helpers.order_path(record)
  end
end
