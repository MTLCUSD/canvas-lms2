class AddCachedUrlToAssignment < ActiveRecord::Migration
  tag :predeploy
  def self.up
    add_column :assignments, :cached_url, :string
  end

  def self.down
    remove_column :assignments, :cached_url
  end
end
