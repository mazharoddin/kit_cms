$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "kit/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "kit"
  s.version     = Kit::VERSION
  s.authors     = ["DSC"]
  s.email       = ["tech@dsc.net"]
  s.homepage    = "http://www.dsc.net"
  s.summary     = "Kit."
  s.description = "Kit."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.1"
  s.add_dependency "devise"
  s.add_dependency "devise-encryptable"
  s.add_dependency "cancan"
  s.add_dependency "formtastic"
  s.add_dependency "mysql2"
  s.add_dependency 'class-table-inheritance'
  s.add_dependency 'mercury-rails'
  s.add_dependency 'rails_admin'
  s.add_dependency 'progress_bar'
end
