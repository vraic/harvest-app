class TaskAssignedNotifier < ApplicationNotifier
  def message
    if record&.responsible_user.present?
      "Task assigned: #{record.title}"
    else
      "New unassigned task: #{record&.title}"
    end
  end

  def target_path
    Rails.application.routes.url_helpers.task_path(record)
  end
end
