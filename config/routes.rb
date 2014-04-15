Excursion::Engine.routes.draw do
  match '*path' => 'excursion#cors_preflight', :via => :options if Excursion.configuration.enable_cors
  match Excursion.configuration.stubbed_route_path => 'excursion#error', :via => [:get, :post, :put], as: :excursion_route_not_found if Excursion.configuration.suppress_errors
end
