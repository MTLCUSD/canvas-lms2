class AddCachedDescriptionToAssignment < ActiveRecord::Migration
  tag :predeploy

  def self.up
  	add_column :assignments, :cached_description, :text, :limit => 16777215
  end

  def self.down
  	remove_column :assignments, :cached_description
  end
end
