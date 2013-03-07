class ChangeTaskColumn < ActiveRecord::Migration
  def up
    rename_column :tasks, :completor_id, :assignee_id
    add_column :tasks, :due_date, :datetime
  end

  def down
    rename_column :tasks, :assignee_id, :completor_id
    remove_column :tasks, :due_date
  end
end
