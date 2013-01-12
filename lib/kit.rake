namespace :kit do

  desc "Empties the database - USE WITH CAUTION"
  task :clean_db => :environment do

    [  "roles", "statuses", "html_assets", "topic_post_edits", "submission_checks", "form_field_types", "comments", "kit_requests", "kit_sessions", "kit_engagements", "locations", "form_field_groups", "form_fields", "systems", "system_identifiers", "preferences", "categories", "forum_users", "users", "layouts", "activities", "ad_clicks", "ad_units", "ad_zones", "ads", "assets", "block_instances", "blocks", "calendar_entries", "calendar_entry_types", "calendars", "category_groups", "conversation_users", "conversations", "design_histories", "events", "experiments", "form_fields", "form_submission_fields", "form_submissions", "forms", "galleries", "gallery_assets", "goals", "goals_users", "group_users", "groups", "kit_engagements", "kit_sessions", "mappings", "menu_items", "menus", "messages", "newsletter_sends", "newsletter_sents", "newsletters", "order_items", "order_payments", "orders", "page_comments", "page_contents", "page_edits", "page_favourites", "page_histories", "page_template_terms", "page_templates", "page_threads", "pages", "post_reports", "snippets", "terms", "thread_views", "ticket_sales", "todos", "topic_categories", "topic_post_votes", "topic_posts", "topic_thread_users", "topic_threads", "topics", "user_attribute_values", "user_attributes", "user_links", "user_notes", "views"].each do |table|
      Object.const_get(table.classify).delete_all
    end
    ActiveRecord::Base.connection.execute("delete from roles_users")
  end

  desc "Create statues"
  task :create_statuses => :environment do
    Status.create(:name=>"Editing", :order_by=>10, :is_default=>1, :system_id=>1)
    Status.create(:name=>"For Review", :order_by=>20, :is_default=>0, :system_id=>1)
    Status.create(:name=>"Ready for Publication", :order_by=>30, :is_default=>0, :system_id=>1)
    Status.create(:name=>"Published", :order_by=>40, :is_default=>0, :system_id=>1, :is_published=>1)
    Status.create(:name=>"Withdrawn", :order_by=>50, :is_default=>0, :system_id=>1)
    Status.create(:name=>"Stub", :order_by=>60, :is_default=>0, :system_id=>1, :is_stub=>1)

  end

  desc "Create roles"
  task :create_roles => :environment do 
    Role.create(:system_id=>1, :name=>"SuperAdmin")
    Role.create(:system_id=>1, :name=>"Admin")
    Role.create(:system_id=>1, :name=>"Editor")
    Role.create(:system_id=>1, :name=>"Moderator")
    Role.create(:system_id=>1, :name=>"Designer")
  end

  desc "Create user"
  task :create_user, [:email, :password] => :environment do |t, args|
    u = User.new
    u.email = args.email
    u.password = args.password
    u.system_id = 1
    u.save
    r = Role.where(:name=>"SuperAdmin").where(:system_id=>1).first
    u.roles << r

    Preference.set(1, "master_user_email", u.email)
    Preference.set(1, "page_click", "info", u.id)
  end

  desc "Create Basic Layout"
  task :basic_layout => :environment do 
    l = Layout.new
    l.name = 'application'
    l.user = User.where(:email=>Preference.get(1, "master_user_email")).first
    l.body = '
!!!

%head
  %meta(charset="utf-8")
  = render :partial=>"layouts/kit_header"  

  %style(type="text/css")
    == div#edit_link{top:30px;}

%body
  = yield
    '
    l.locale = 'en'
    l.handler = 'haml'
    l.format = 'html'
    l.stylesheets = 'application'
    l.system_id = 1
    l.javascripts = 'application'
    l.path = 'layouts/application'
    l.save!
  end
 
  desc "Create Basic Assets"
  task :basic_assets => :environment do 
    a = HtmlAsset.new
    a.name = 'application'
    a.body = "
    body {
      font-family: 'sans serif';
    }
    "
    a.user = User.where(:email=>Preference.get(1, "master_user_email")).first
    a.system_id = 1
    a.file_type = 'css'
    a.save!

    a = HtmlAsset.new
    a.name = 'application'
    a.body = "
    function test_alert() {
      alert('Test');
    }
    "
    a.user = User.where(:email=>Preference.get(1, "master_user_email")).first
    a.system_id = 1
    a.file_type = 'js'
    a.save!
  end

  desc "Set Basic Preferences"
  task :basic_preferences => :environment do
    admin = User.where(:email=>Preference.get(1, "master_user_email")).first.email

    Preference.set(1, "report_post_notification", admin)
    Preference.set(1, "notifications_from", admin)
    Preference.set(1, "host", "http://localhost:3000")
    Preference.set(1, "site_name", "Kit CCMS")
    Preference.set(1, "eu_cookies", "false")
    Preference.set(1, "app_name", "Kit")
    Preference.set(1, "date_time_format", "%H:%M %d-%m-%s")
    Preference.set(1, "spam_points_to_ban_user", "5")
    Preference.set(1, "use_forum_topic_catgories", "false")
    Preference.set(1, "notify", admin)
    Preference.set(1, "no_debug", "true")
    Preference.set(1, "forum_users_profile_link", "true")
    Preference.set(1, "feature_*", "true")
    Preference.set(1, "show_topic_info_in_index", "true")
    Preference.set(1, "forum_show_mini_profile", "true")
    Preference.set(1, "forum_post_edit_time", "5")
    Preference.set(1, "use_rest_auth", "true")
    Preference.set(1, "use_captcha", "false")
    Preference.set(1, "show_groups", "true")

    UserLink.create(:user_id=>nil, :label=>"Browse", :url=>"/pages")
    UserLink.create(:user_id=>nil, :label=>"New Page", :url=>"/pages/new")
    
    System.create(:system_id=>1, :name=>'kit')
    SystemIdentifier.create(:system_id=>1, :ident_type=>"hostname", :ident_value=>"localhost")
  end

  desc "Create Home Page"
  task :basic_homepage => :environment do 
    Rails.logger.level = Logger::DEBUG
    master = User.where(:email=>Preference.get(1,"master_user_email")).first
    editor = User.where(:email=>master.email).first
    p = Page.new(:full_path=>"/index", :category_id=>Category.root(1).id, :status=>Status.default_status(1), :name=>"index", :title=>"Home Page", :page_template_id=>PageTemplate.sys(1).where(:is_default=>1).first.id, :created_by=>editor.id, :updated_by=>editor.id, :system_id=>1)
    p.save!

    pc = PageContent.new
    pc.page_id = p.id
    pc.value = 'Welcome to Kit Community and Content Management System'
    pc.user = master
    pc.field_name = 'body'
    pc.system_id = 1
    pc.version = 0
    pc.save
    p.publish(editor.id)


  end

  desc "Create Category Tree"
  task :basic_tree => :environment do
    Category.create(:name=>"/", :parent_id=>0, :is_visible=>1, :path=>"/", :is_readable_anon=>1, :system_id=>1)
  end

  desc "Create Basic Template"
  task :basic_template => :environment do
    pt = PageTemplate.new
    pt.name = 'Basic'
    pt.body = '= field("body")'
    pt.header = ''
    pt.footer = ''
    pt.page_type = 'basic'
    pt.layout = Layout.where(:system_id=>1).where(:name=>"application").first
    pt.template_type = 'haml'
    pt.display_order = 1
    pt.is_mobile = 0
    pt.is_default = 1
    pt.system_id = 1
    pt.user = User.where(:email=>Preference.get(1, "master_user_email")).first
    pt.save!
  end


  desc "extracting data for fixtures"
  task :extract_fixtures => :environment do
    sql  = "SELECT * FROM %s"
    skip_tables = ["schema_info","schema_migrations"]
    ActiveRecord::Base.establish_connection
    (ActiveRecord::Base.connection.tables - skip_tables).each do |table_name|
      i = "000"
      File.open("#{RAILS_ROOT}/test/fixtures/#{table_name}.yml", 'w' ) do |file|
        data = ActiveRecord::Base.connection.select_all(sql % table_name)
        file.write data.inject({}) { |hash, record|
          hash["#{table_name}_#{i.succ!}"] = record
          hash
        }.to_yaml
      end
    end
  end

  desc "Initial Kit Setup" 
  task :setup, [:email, :password] => :environment do |t, args|
    Rake::Task['db:create']
    Rake::Task['db:schema:load']
    Rake::Task['db:data:load']
    Rake::Task['kit:clean_db']
    Rake::Task['kit:create_user'].invoke(args.email, args.password)
    Rake::Task['kit:create_statuses']
    Rake::Task['kit:create_roles']
    Rake::Task['kit:basic_assets']
    Rake::Task['kit:basic_layout']
    Rake::Task['kit:basic_preferences']
    Rake::Task['kit:basic_template']
    Rake::Task['kit:basic_homepage']
  end

  
end
