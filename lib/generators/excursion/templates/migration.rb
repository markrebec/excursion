class CreateExcursionRoutePool < ActiveRecord::Migration
  def self.up
    create_table :excursion_route_pool, :force => true do |table|
      table.string :key, :null => false
      table.text   :value, :null => false
    end

    add_index :excursion_route_pool, :key, :name => 'excursion_route_pool_key', :unique => true
  end

  def self.down
    drop_table :excursion_route_pool
  end
end
