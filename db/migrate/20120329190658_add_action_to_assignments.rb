class AddActionToAssignments < ActiveRecord::Migration
  tag :postdeploy
  def self.up
    add_column :assignments, :action, :string
  end

  def self.down
    remove_column :assignments, :action
  end
end
