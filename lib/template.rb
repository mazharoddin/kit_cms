#gem("rspec-rails", :group => "test")
#gem("cucumber-rails", :group => "test")
 
#if yes?("Would you like to install Devise?")
#  gem("devise")
#  generate("devise:install")
#  model_name = ask("What would you like the user model to be called? [user]")
#  model_name = "user" if model_name.blank?
#  generate("devise", model_name)
#end
#

gem 'rails', :version=>'3.2.2'

gem 'mysql2'
gem 'gnric', :path=>'~/dev/gnric'  
gem 'devise'
gem 'formtastic'
gem 'cancan'
gem 'class-table-inheritance'
gem 'haml'
gem 'mercury-rails', :git=>"git://github.com/dadamsuk/mercury.git"
gem 'best_in_place', :git=>"git://github.com/dadamsuk/best_in_place.git"
gem "will_paginate"
gem "rmagick"
gem 'dynamic_form'
gem "paperclip", :version=>"~> 2.3"
gem 'jquery-rails'
gem 'execjs'
gem 'therubyracer'
gem 'rails_admin', :git => 'git://github.com/sferik/rails_admin.git'
#gem 'sunspot_rails'
#gem 'sunspot_solr' # optional pre-packaged Solr distribution for use in development
gem 'progress_bar'

gem 'sass-rails', :group=>:assets, :version=>'~> 3.2.3' 
gem 'coffee-rails', :group=>:assets, :version=>'~> 3.2.1'

gem 'uglifier', :version=>'>= 1.0.3'

gem 'jquery-rails'

generate("devise:install")
generate("devise", "user")



