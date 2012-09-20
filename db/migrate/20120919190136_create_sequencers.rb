class CreateSequencers < ActiveRecord::Migration
  def change
    create_table :sequencers do |t|
      t.string "name"
      t.string "address"
      t.float "latitude"
      t.float "longitude"
      t.string "description"
      t.integer "owner"
      t.string "website"
      t.string "type"
      t.timestamps
    end
  end
end
