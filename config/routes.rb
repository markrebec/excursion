Excursion::Engine.routes.draw do
  match '*path' => 'application#cors_preflight', :via => :options if Excursion.configuration.enable_cors
end
