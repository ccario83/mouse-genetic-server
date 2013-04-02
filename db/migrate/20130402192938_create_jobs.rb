class CreateJobs < ActiveRecord::Migration
  def up
    create_table :jobs do |t|
      t.integer :creator_id
      t.integer :datafile_id
      t.string :name
      t.text :description
      t.string :algorithm
      t.string :snpset
      t.string :location
    
      t.timestamps
    end
    
    add_index :jobs, :creator_id
  end

  def down
    remove_index :jobs, :creator_id
    drop_table :jobs
  end
end
