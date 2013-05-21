class AddResultfileToJob < ActiveRecord::Migration
  def change
    add_column :jobs, :resultfile, :string
  end
end
