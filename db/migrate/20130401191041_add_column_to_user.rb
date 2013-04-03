class AddColumnToUser < ActiveRecord::Migration
  def change
    add_column :users, :directory, :string
    add_index :users, :directory
  end
end
