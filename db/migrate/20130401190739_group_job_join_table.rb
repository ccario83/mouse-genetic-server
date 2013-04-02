class GroupJobJoinTable < ActiveRecord::Migration
  def up
    create_table :groups_jobs, :id => false do |t|
      t.references :group
      t.references :job
    end
    
    add_index :groups_jobs, [:group_id, :job_id], :unique => true
  end

  def down
    remove_index :groups_jobs, [:group_id, :job_id]
    drop_table :groups_jobs
  end
end
