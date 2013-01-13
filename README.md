Kit
===

THIS IS ALPHA SOFTWARE.  DO NOT USE.

Whilst the code in this release has been in production use for over a year, the release of it as open source is new, the packaging of it as a gem is new and this documentation is new.  If you're interested come back in a few days when the installation procedure etc. should be all sorted.  



Kit is the Community and Content Management engine for Ruby on Rails 3.1 and above.  Kit can be used as an entire CMS-based
website or add CMS functionality to an existing Rails application.  It has the following features:

1. WYSIWYG editor (courtesy of Mercury Rails) with in-place editing. Content versioning, multi-user support, etc.
2. Flexible layouts and templates, CSS and javascript managed from within the browser, without restrictions.
3. Discussion forums with in-place moderation
4. Fast flexible searching
5. Drag and drop file upload and comprehensive asset management
6. Modules including image carousels, calendars, advertising, menus, twitter feed, RSS feed, etc.
7. Easily extended with reuseable components, easily created in HTML and Ruby.
8. User management, user grouping
9. Integration with Mailchimp

Installation
------------

NOT YET COMPLETE. DO NOT TRY FOLLOWING THESE INSTRUCTIONS YET.

# To build a Rails app using this gem, first create your Rails app:

  rails new my_cms
  cd my_cms
  
# Edit the Gemfile to include MySQL and the Kit CMS gems:

  # add these lines to Gemfile, around line 8
  gem 'mysql2'
  gem 'kit_cms'
  
# Then build the bundle:

  bundle
  
# Edit the config/database.yml file to point to a local, not-yet-existing databsae:

  development:
  adapter: mysql2
  database: mycms_development
  hostname: localhost
  pool: 5
  timeout: 5000

# Create the database:

  rake db:create
  
# Setup the database:

  rake kit:setup_db
  
# Setup the CMS:

  rake kit:setup_cms
  
# Start your Rails app:

  rails s
  
# Visit this URL:

  http://localhost:3000/db
  
  
  






