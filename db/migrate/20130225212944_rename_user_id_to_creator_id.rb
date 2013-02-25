class RenameUserIdToCreatorId < ActiveRecord::Migration
  def up
    rename_column :groups, :user_id, :creator_id
  end

  def down
    rename_column :groups, :creator_id, :user_id
  end
end
