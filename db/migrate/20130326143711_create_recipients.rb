class CreateRecipients < ActiveRecord::Migration
  def change
    create_table :recipients do |t|
      t.integer :recipient_id
      t.string :recipient_type
      t.integer :micropost_id

      t.timestamps
    end
  end
end
