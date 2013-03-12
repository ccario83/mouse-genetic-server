class RenameGroupsUsersToMemberships < ActiveRecord::Migration
  def change
    rename_table :groups_users, :memberships
    add_column :memberships, :id, :primary_key
  end
end
