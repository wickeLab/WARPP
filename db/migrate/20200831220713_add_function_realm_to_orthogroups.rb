class AddFunctionRealmToOrthogroups < ActiveRecord::Migration[5.2]
  def change
    add_column :orthogroups, :function_realm, :text, array: true, default: ['unknown']
  end
end
