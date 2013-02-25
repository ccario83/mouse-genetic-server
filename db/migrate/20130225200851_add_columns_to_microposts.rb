class AddColumnsToMicroposts < ActiveRecord::Migration
  def change
    add_column :microposts, :creator_id, :integer
    add_column :microposts, :recipient_id, :integer
    add_column :microposts, :recipient_type, :string
  end
end
