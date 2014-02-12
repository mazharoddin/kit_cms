Kit
===

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
10. Fast and sophisticated searching with ElasticSearch
11. Create complex forms and provide instant or completely customised views of the data submitted.
12. Lots more.

Commercial Support
------------------

Commercial support, hosting, customisation and other assistance is available from the authors of Kit, [DSC](http://www.dsc.net).

Example Sites
-------------

The following sites use Kit.  None of them have any custom functionality not already present in the Kit gem.

* [Working With Rails](http://www.workingwithrails.com)
* [Women's Sport and Fitness Foundation](http://www.wsff.org.uk)
* [EuroGA](http://www.euroga.org)

Note
----

The Kit system has been deployed in several production environments for over a year, on Linux servers with Passenger and MySQL.  However, the production of an open source Gem 
is new as of January 2013.  As such, the installation procedure, documentation and use on other platforms is new.  Please let us know if you 
encounter any difficulties.  

Installation
------------

Kit CMS is provided as a Rails engine.  Therefore it is possible to add Kit's functionality to an existing app or you can create a new app in which 
to run it.  To create a new app, which is probably the easiest option if you want to explore what Kit has to offer, follow the step-by-step instructions below.  
Advice for those wishing to use Kit as an addition to an existing system are also below.  Finally, we also have a sample app with almost everything installed
and ready to run.  For details of that please see [kit_app on Github](https://github.com/dsc-os/kit_app).

To build a Rails app using this gem, first create your Rails app:

    rails new my_cms
    cd my_cms
  
Edit the Gemfile to include MySQL,the Kit CMS and thin server gems:

    # add these lines to Gemfile, around line 8
    gem 'mysql2'
    gem 'kit_cms'
    gem 'thin'
  
Then build the bundle:

    bundle
  
Edit the config/database.yml file to point to a local, not-yet-existing databsae:

    # edit config/database.yml to have a section like this
    development:
    adapter: mysql2
    database: mycms_development
    hostname: localhost
    pool: 5
    timeout: 5000

Now to install and run ElasticSearch, which must be running before you start your CMS.  Download the latest version from (http://www.elasticsearch.org/download/).  
Extract the contents of the file you downloaded in to a fresh directory called `elasticsearch` then do:

    cd elasticsearch
    bin/elasticsearch -f
    
This will start the search engine in foreground mode.  Drop the -f to run in background mode.  Once that's running, we need to continue with the CMS setup.    
  
Setup the CMS:

    rake kit:setup_cms
  
Start the Rails app:

    rails s thin
  
Visit the home page:

    http://localhost:3000
    
To edit the home page and use all the other functions:

    http://localhost:3000/db
    
Login, then click the Dashboard link that will appear on the home page.  Or click the Edit link to edit the home page in place.

  
Adding Kit to an Existing System
--------------------------------

Kit is a Rails Engine and can be added to any existing Rails application. To do this include the `kit_cms` gem in your Gemfile and rebuild your bundle.  You will need to 
create the various tables as described in the gem's db/schema.rb file and populate them with the data from db/data.yml.  You should then be able to run the kit:setup_cms 
rake task as listed above.  One issue you may face is name clashes with your existing tables.  As Kit was abstracted from an existing system many of the table
names are fairly common, like 'users', 'pages' etc. At some point in the future we hope to release a version which provides Kit's own tables in their own 
namespace, e.g. 'kit_users', 'kit_pages' etc.  If you've not yet built the wider system or you have one with limited functionality 
it's probably easiest to follow the instructions above for creating a new application with Kit, then building your new functionality or retrofitting your 
existing code in to that app.  Note that you'll need to follow the instructions above to download and run ElasticSearch, unless it's already running.


  






