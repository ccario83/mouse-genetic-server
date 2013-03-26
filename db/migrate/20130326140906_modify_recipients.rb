class ModifyRecipients < ActiveRecord::Migration
  def up
    remove_column :microposts, :recipient_id
    create_table :communications do |t|
      t.integer :recipient_id
      t.string :recipient_type
      t.integer :micropost_id
    end
    
  end

  def down
    drop_table :communications
    add_column :microposts, :recipient_id, :integer
  end
end
