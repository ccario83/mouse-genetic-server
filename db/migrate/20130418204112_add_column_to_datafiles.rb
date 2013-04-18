class AddColumnToDatafiles < ActiveRecord::Migration
  def change
    add_column :datafiles, :uwf_runnable, :boolean, :default => false
  end
end
