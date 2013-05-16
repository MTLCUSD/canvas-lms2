class AddUrlToAssignments < ActiveRecord::Migration
  tag :postdeploy
  def self.up
    add_column :assignments, :url, :string
  end

  def self.down
    remove_column :assignments, :url
  end
end
