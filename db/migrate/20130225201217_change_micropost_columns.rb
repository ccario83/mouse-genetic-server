class ChangeMicropostColumns < ActiveRecord::Migration
  def up
    remove_index :microposts, [:user_id, :created_at]
    remove_column :microposts, :user_id
    add_index :microposts, [:recipient_id, :recipient_type, :created_at], :name => 'index_microposts_on_recipient'
  end

  def down
    remove_index :microposts, [:recipient_id, :recipient_type, :created_at]
    add_column :microposts, :user_id
    add_index :microposts, [:user_id, :created_at]
  end
end
