class MakeTaskResponsibleUserOptional < ActiveRecord::Migration[8.1]
  def change
    change_column_null :tasks, :responsible_user_id, true
  end
end
