class Excursion::RoutePool < ::ActiveRecord::Base
  self.table_name = 'excursion_route_pool'
  serialize :value
  attr_accessible :key, :value if Excursion.rails3?
end
