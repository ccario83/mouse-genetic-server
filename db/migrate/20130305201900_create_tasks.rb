class CreateTasks < ActiveRecord::Migration
  def up
    create_table :tasks do |t|
      t.string :description
      t.integer :group_id
      t.integer :creator_id
      t.integer :completor_id
      t.boolean :completed, :default => false
      t.timestamps
    end
  end
  
  def down
    drop_table :tasks
  end
end

