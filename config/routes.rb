Excursion::Engine.routes.draw do
  match '*path' => 'excursion#cors_preflight', :via => :options if Excursion.configuration.enable_cors
end
