$:.push File.expand_path("../lib", __FILE__)
require "excursion/version"

Gem::Specification.new do |s|
  s.name        = "excursion"
  s.version     = Excursion::VERSION
  s.summary     = "Route pooling to share routes between applications"
  s.description = "Provides a pool of routes into which applications can dump their host information and routing table. Other applications can then utilize application namespaced helper methods for redirecting, etc. between apps."
  s.authors     = ["Mark Rebec"]
  s.email       = ["mark@markrebec.com"]
  s.files       = Dir["lib/**/*"]
  s.test_files  = Dir["spec/**/*"]
  s.homepage    = "http://github.com/markrebec/excursion"

  s.add_dependency "rails"
  
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "sqlite3"
end
