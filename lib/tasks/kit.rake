namespace :kit do

  desc "Setup the database - USE WITH CAUTION"
  task :setup_db => :environment do
    require 'fileutils'
    ok = true
    source_dir = `bundle show kit_cms`.strip
    ['schema.rb', 'data.yml'].each do |fn|
      source = File.join(source_dir, 'db', fn)
      dest = File.join('db', fn)
      if File.exists?(dest)
        puts "'#{dest}' already exists, I'm not going to overwrite it. If you want to use the Kit #{fn.split('.')[0]} you will have to delete or move that file out of the way.\n\n" 
        ok = false
      else
        FileUtils.copy(source, dest)
      end
    end

    if ok
      Rake::Task['db:reset'].invoke
      puts "The next step will take a while (at least 60 seconds and depending on your system could be several minutes) and no progress will be shown."
      Rake::Task['db:data:load'].invoke
    else
      puts "As one of the file copy operations failed I'm not going to create your database. Resolve the copying issue and run this command again.\n\n"
    end
  end  

  desc "Empties the database - USE WITH CAUTION"
  task :clean_db => :environment do

    [  "roles", "statuses", "html_assets", "topic_post_edits", "submission_checks", "form_field_types", "comments", "kit_requests", "kit_sessions", "kit_engagements", "locations", "form_field_groups", "form_fields", "systems", "system_identifiers", "preferences", "categories", "forum_users", "users", "layouts", "activities", "ad_clicks", "ad_units", "ad_zones", "ads", "assets", "block_instances", "blocks", "calendar_entries", "calendar_entry_types", "calendars", "category_groups", "conversation_users", "conversations", "design_histories", "events", "experiments", "form_fields", "form_submission_fields", "form_submissions", "forms", "galleries", "gallery_assets", "goals", "goals_users", "group_users", "groups", "mappings", "menu_items", "menus", "messages", "newsletter_sends", "newsletter_sents", "newsletters", "order_items", "order_payments", "orders", "page_comments", "page_contents", "page_edits", "page_favourites", "page_histories", "page_template_terms", "page_templates", "page_threads", "pages", "post_reports", "snippets", "terms", "thread_views", "ticket_sales", "todos", "topic_categories", "topic_post_votes", "topic_posts", "topic_thread_users", "topic_threads", "topics", "user_attribute_values", "user_attributes", "user_links", "user_notes", "views"].each do |table|
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
  task :create_user => :environment do 

    print "\nEmail address of master administrator? > "
    email = STDIN.gets.chomp
    print "\nPassword for master administator? > "
    password = STDIN.gets.chomp

    u = User.new
    u.email = email
    u.password = password
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
    l.system_id = 1
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

    s = System.new
    s.id = 1
    s.system_id = 1
    s.name = 'kit'
    s.save
    si = SystemIdentifier.new
    si.system_id = 1
    si.ident_type = 'hostname'
    si.ident_value = 'localhost'
    si.save
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
    p.make_home_page!

    original_index = File.join("public", "index.html")
    if File.exists?(original_index)
      FileUtils.mv(original_index, File.join("public","index.html.old"))
      puts "Original /public/index.html has been renamed /public/index.html.old"
    end
  end

  desc "Create Category Tree"
  task :basic_tree => :environment do
    c = Category.new
    c.name="/"
    c.parent_id = 0
    c.is_visible=1
    c.path="/"
    c.is_readable_anon=1
    c.system_id=1
    c.save
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

  desc "Reset Password"
  task :reset_password => :environment do 
    print "\nThis will reset the password of any admin user in any system. Typically you will use this to reset the superadmin account to allow access to the CMS Dashboard from where you can reset any other passwords. \n\nFirst you must select the system ID from this list:\n\n"

    System.all.each do |s|
      puts "#{s.id} : #{s.name}"
    end
    print "\nSystem ID? "
    system_id = STDIN.gets.chomp
   
    s = System.sys(system_id).first
    unless s
      puts "That System ID isn't valid.  You'll have to start again.\n\n"
      exit -1
    end
     
    puts "\nAdmin users of '#{s.name}':\n"
    User.sys(system_id).includes(:roles).each do |u|
      puts "User ID: #{u.id} Email: #{u.email}" if u.admin?
    end

    print "\nWhat is the User ID of the user whose password you want to change? "
    user_id = STDIN.gets.chomp

    u = User.sys(system_id).where(:id=>user_id).first

    unless u
      puts "That User ID isn't valid.  You'll have to start again.\n\n"
      exit -1
    end

    u = User.find(user_id)

    print "\nFinally, enter a new password for #{u.email} within #{s.name}: "

    password = STDIN.gets.chomp
    if password.strip.length<=0
      puts "\n\nThis utility has no restrictions on password complexity, but won't set an empty password.  You'll have to start again.\n\n"
      exit -1
    end

    u.password = password
    u.save

    puts "\nThe password has been changed. You should now sign in as '#{u.email}' with the new password '#{password}', then change the password from within the dashboard.\n\n"
  end
    

  desc "Initial Kit Setup" 
  task :setup_cms, [:email, :password] => :environment do |t, args|

    print "\nThis will remove ALL existing Kit CMS data. If you enter anything other than 'YES' (without quotes) I'll stop.\n\nAre you sure? > "
    confirm = STDIN.gets.chomp
    exit unless confirm == 'YES'
    Rake::Task['kit:clean_db'].invoke
    Rake::Task['kit:create_roles'].invoke
    Rake::Task['kit:create_user'].invoke
    Rake::Task['kit:create_statuses'].invoke
    Rake::Task['kit:basic_assets'].invoke
    Rake::Task['kit:basic_layout'].invoke
    Rake::Task['kit:basic_preferences'].invoke
    Rake::Task['kit:basic_template'].invoke
    Rake::Task['kit:basic_tree'].invoke
    Rake::Task['kit:basic_homepage'].invoke
    puts "\nStart the Rails server then visit http://localhost:3000 or to login to the administrative dashboard go to http://localhost:3000/db\n\n"
  end


  desc "Upgrade Stylesheets and Javascripts"
  task :upgrade_assets => :environment do 

      Layout.all.each do |layout|
        puts "Doing Layout #{layout.name} for System #{layout.system_id}"
        puts "stylesheets #{layout.stylesheets}"
        layout.stylesheets.split(",").each do |s|
          puts "Doing stylesheet '#{s}'"
          layout.html_assets << HtmlAsset.sys(layout.system_id).where(:name=>s).where(:file_type=>'css').first rescue nil
        end if layout.stylesheets
      end
      Layout.all.each do |layout|
        layout.javascripts.split(",").each do |s|
          layout.html_assets << HtmlAsset.sys(layout.system_id).where(:name=>s).where(:file_type=>'js').first rescue nil
        end if layout.javascripts
      end
      PageTemplate.all.each do |pt|
        puts "Doing PT #{pt.name} for System #{pt.system_id}"
        pt.stylesheets.split(",").each do |s|
          pt.html_assets << HtmlAsset.sys(pt.system_id).where(:name=>s).where(:file_type=>'css').first rescue nil
        end if pt.stylesheets
      end
      PageTemplate.all.each do |pt|
        pt.javascripts.split(",").each do |s|
          pt.html_assets << HtmlAsset.sys(pt.system_id).where(:name=>s).where(:file_type=>'js').first rescue nil
        end if pt.javascripts
      end
      Form.all.each do |f|
        puts "Doing form #{f.title} for System #{f.system_id}"
        f.stylesheets.split(",").each do |s|
          f.html_assets << HtmlAsset.sys(f.system_id).where(:name=>s).where(:file_type=>"css").first rescue nil
        end if f.stylesheets
      end
  end

end
