class CreateDatafiles < ActiveRecord::Migration
  def up
    create_table :datafiles do |t|
      t.integer :owner_id
      t.string :filename
      t.text :description
      t.string :directory
    
      t.timestamps
    end
  
    add_index :datafiles, :owner_id
  end

  def down
    remove_index :datafiles, :owner_id
    drop_table :datafiles
  end
end
