$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "kit/version"

# Describe your s.gem and declare its dependencies:
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
  s.add_dependency "mysql2"
  s.add_dependency 'class-table-inheritance'
  s.add_dependency 'mercury-rails'
  s.add_dependency "tire"
  s.add_dependency "delayed_job_active_record"
  s.add_dependency "daemons"
  s.add_dependency "kaminari"
  s.add_dependency "twitter"
  s.add_dependency "yaml_db"
  s.add_dependency "devise"
  s.add_dependency "devise-encryptable"
  s.add_dependency "cancan"
  s.add_dependency "haml"
  s.add_dependency 'mercury-rails'
  s.add_dependency 'best_in_place'
  s.add_dependency "rmagick"
  s.add_dependency "paperclip", "~> 2.3"
  s.add_dependency 'jquery-rails'
  s.add_dependency 'ruby-stemmer'
  s.add_dependency 'browser'
  s.add_dependency 'panoramic'
  s.add_dependency 'nifty-generators'
  s.add_dependency 'country_select'
  s.add_dependency 'geocoder'
  s.add_dependency "truncate_html"
  s.add_dependency "file-tail"
  s.add_dependency "sanitize"
  s.add_dependency 'rdiscount'
  s.add_dependency 'gibbon'
  s.add_dependency 'imgkit'


end
