class GroupUserJoinTables < ActiveRecord::Migration
  def change
    # For the Group/User membership
    create_table :groups_users, :id => false do |t|
      t.references :group
      t.references :user
      t.boolean :confirmed => {:default => false}
    end

    add_index(:groups_users, [:group_id, :user_id], :unique => true)
    
  end
end
