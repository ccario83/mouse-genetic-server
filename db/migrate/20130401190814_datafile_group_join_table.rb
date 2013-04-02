class DatafileGroupJoinTable < ActiveRecord::Migration
  def up
    create_table :datafiles_groups, :id => false do |t|
      t.references :datafile
      t.references :group
    end
    
    add_index :datafiles_groups, [:datafile_id, :group_id], :unique => true
  end

  def down
    remove_index :datafiles_groups, [:datafile_id, :group_id]
    drop_table :datafiles_groups
  end
end
