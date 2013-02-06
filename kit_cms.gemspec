$:.push File.expand_path("../lib", __FILE__)

# Describe your s.gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "kit_cms"
  s.version     = "2.3.20"
  s.authors     = ["DSC"]
  s.email       = ["os@dsc.net"]
  s.homepage    = "https://github.com/dsc-os/kit_cms"
  s.summary     = "Community and Content Management System as a Rails 3.2+ Engine"
  s.description = "Kit is DSC's Community and Content Management System (CCMS) built as a Rails engine for Rails 3.1 and above. It provides an entire application's worth of CMS functions including in-place WYSIWYG editing with versioning, flexible layouts and templates, CSS and JS all managed within your browser, drag and drop image/file uploading, modules for sophisticated forums (with in place moderation) asset management, calendars, advertising, menus, RSS feeds, re-useable components, full audit trail of editing, integration with mailchimp, Google Analytics and lots more."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.1"
  s.add_dependency "mysql2"
  s.add_dependency 'class-table-inheritance'
  s.add_dependency 'kiteditor', "~> 1.0.5"
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
  s.add_dependency 'best_in_place'
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
  s.add_dependency 'maruku'
  s.add_dependency 'gibbon'
  s.add_dependency 'imgkit'
  s.add_dependency 'dynamic_form'


end
