$:.push File.expand_path("../lib", __FILE__)
require "excursion/version"

Gem::Specification.new do |s|
  s.name        = "excursion"
  s.version     = Excursion::VERSION
  s.summary     = "Cross-application route pooling, javascript helpers and CORS"
  s.description = "Provides optional javascript url helpers, CORS configuration and a pool of routes into which applications can dump their host information and routing table. Other applications can then utilize application namespaced helper methods for redirecting, drawing links, placing cross-origin XHR requests, etc. between apps."
  s.authors     = ["Mark Rebec"]
  s.email       = ["mark@markrebec.com"]
  s.files       = Dir["lib/**/*", "app/**/*", "config/**/*"]
  s.test_files  = Dir["spec/**/*"]
  s.homepage    = "http://github.com/markrebec/excursion"
  s.license     = "MIT"

  s.add_dependency "rails", ">= 3.0.0"

  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "dalli"
end
