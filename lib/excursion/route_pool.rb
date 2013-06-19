class Excursion::RoutePool < ActiveRecord::Base
  self.table_name = 'excursion_route_pool'
  serialize :value
end
