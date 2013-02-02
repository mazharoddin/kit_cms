Rails.application.routes.draw do

  devise_for :users, :controllers=>{:sessions=>"user/sessions", :registrations=>"user/registrations", :passwords=>"user/passwords", :unlocks=>"user/unlocks", :confirmations=>"user/confirmations"}

  namespace "admin" do
    resources :snippet
    resources :mapping
    resources :layouts
    resources :page_templates
    resources :blocks
    resources :calendars
    resources :calendar_entries
    resources :views
    resources :page_template_terms
    resources :form_field_types 
    resources :form_field_groups 
    resources :form
    resources :ad_units
    resources :ad_zones
    resources :ads
    resources :notices
    resources :goals
    resources :experiments
  end

  get '/plumb' => 'admin/dashboard#plumb'
  get '/admin/salesforce' => 'admin/dashboard#salesforce'
  get '/admin/goals/:id/scores' => 'admin/goals#scores'
  get '/admin/engagements' => 'admin/kit_engagement#index'
  post '/admin/ad/:id/activate/:mode' => 'admin/ads#activate'
  post '/admin/ad_unit/:id/create_block' => 'admin/ad_units#create_block'
  get '/admin/advertisments' => 'admin/advertisments#index'
  get '/admin/orders' => 'admin/order#index'
  get '/admin/order/:id' => 'admin/order#show'
  get '/admin/order/payment/:id' => 'admin/order#payment'

  post '/ad/buy' => 'ad#buy'
  get '/ad/clicked/:id' => 'ad#clicked'
  post "/order/pay_for_tickets" => 'order#pay_for_tickets'
  post "/order/pay_for_ads" => 'order#pay_for_ads'
  get '/order/sp/success' => 'order#sage_pay_success'
  get '/order/sp/failure' => 'order#sage_pay_failure'

  match "/admin/form_field_types/:id/editoptions" => "admin/form_field_types#editoptions", :only=>[:get, :put]
  match "/calendar/entry" => "calendar#update_entry", :only=>[:put, :post]
  post "/calendar/sell_tickets_setup" => "calendar#sell_tickets_setup"
  get "/admin/calendar_entries/:id/sold" => "admin/calendar_entries#sold" 
  post "/admin/calendar_entries/:id" => "admin/calendar_entries#show" 
  get "/admin/calendars/:calendar_id/:start_date/:id" => "admin/calendar_entries#show"
  get "/admin/page_templates/:id/pages" => "admin/page_templates#pages"
  get "/admin/page_templates/:id/mapping" => "admin/page_templates#mapping"
  match "/tickets/:item_model/:item_id" => "calendar#buy_tickets"
  get "/tickets/sold_as_csv/:item_model/:item_id" => "calendar#sold_as_csv"

  get "/form/:id"  => "form#show"
  post "/form/:id" => "form#save"
  match "/form/search/:form_id" => "form#search"
  get "/admin/forms" => "admin/form#index"
  get "/admin/form/:id/generate_html" => "admin/form#generate_html"
  get "/admin/form/submission/:id" => "admin/form#show_submission"
  delete "/admin/form/submission/:id" => "admin/form#delete_submission"
  post "/admin/form/submission/:id/destroy" => "admin/form#destroy_submission"
  post "/admin/form/submission/:id/showhide/:mode" => "admin/form#show_hide_submission"
  post "/admin/form/submission/:id" => "admin/form#update_submission"
  match "/admin/form/:id/field/:field_id" => "admin/form#field", :only=>[:get, :post]
  get "/admin/form/:id/fields" => "admin/form#fields"
  post "/admin/form/:id/fields" => "admin/form#update_fields"
  get "/admin/forms/:id/list" => "admin/form#list"
  get "/admin/forms/:id/browse" => "admin/form#browse"
  get "/admin/forms/:id/export" => "admin/form#export"

#  get "/kit/css/*path" => "admin/html_asset#serve"
#  get "/kit/js/*path" => "admin/html_asset#serve"
  get "admin/html_assets" => "admin/html_asset#index"
  get "admin/html_asset/:id" => "admin/html_asset#show"
  post "admin/html_asset/:id" => "admin/html_asset#update"
  put "admin/html_asset" => "admin/html_asset#create"
  delete "admin/html_asset/:id" => "admin/html_asset#destroy"

  put 'admin/gallery/image/:id/update' => 'admin/gallery#update_image'
  get "admin/gallery/:id/edit" => "admin/gallery#edit"
  get "admin/gallery/:id/preview" => "admin/gallery#view"
  get "admin/gallery/:id" => "admin/gallery#show"
  get "admin/galleries" => "admin/gallery#index"
  delete "admin/gallery/:id" => "admin/gallery#delete"
  post "admin/galleries" => "admin/gallery#create"
  put "admin/gallery/:id" => "admin/gallery#update"

  post "admin/gallery/:id/images/sort" => "admin/gallery#sort_images"
  post "admin/gallery/:id/image/:image_id" => "admin/gallery#add_image"
  delete "admin/gallery/:id/image/:image_id" => "admin/gallery#delete_image"
  
  match 'db/analytics/setup' => 'admin/analytics#setup', :only=>[:get, :post]
  get 'db/analytics' => 'admin/analytics#index'

  get 'admin/dashboard/logfile' => 'admin/dashboard#logfile' 
  post 'admin/dashboard/user_comment/:id' => 'admin/dashboard#user_comment'
  get 'admin/dashboard/user_comments' => 'admin/dashboard#user_comments'
  match 'admin/dashboard/errors' => 'admin/dashboard#events', :only=>[:get, :delete]
  get 'admin/dashboard/error/:id' => 'admin/dashboard#event' 
  post 'admin/dashboard/maintenance' => 'admin/dashboard#maintenance'
  put 'admin/system/:attr' => 'admin/dashboard#update_preference'
  post 'admin/system/:attr/:value' => 'admin/dashboard#system_settings'
  get 'admin/system' => 'admin/dashboard#system'
  get 'admin/sysadmin' => 'admin/dashboard#sysadmin'
  get 'admin/integrity' => 'admin/dashboard#integrity'

  get 'db/error' => 'admin/dashboard#error'
  get 'db/help(/:url)' => 'admin/dashboard#help'
  get 'db' => 'admin/dashboard#index'

  get 'admin/help/images' => 'admin/help#images'
  delete 'admin/help/image/:id' => 'admin/help#delete_image'
  post 'admin/help/upload' => 'admin/help#upload'
  get 'admin/helps' => 'admin/help#index'
  get 'admin/help/:id/edit' => 'admin/help#edit'
  delete "admin/help/:id" => 'admin/help#destroy'
  post 'admin/helps' => 'admin/help#create'
  post 'admin/help/:id' => 'admin/help#update'

  post 'convo/suggest_game' => 'messaging#suggest_game'
  post 'convo/game/:game_id/start/:opponent_id' => 'messaging#game_start'
  post 'convo/game/:id/:available' => 'messaging#game_availability'
  put 'convo/:id' => 'messaging#message'
  post 'convo' => 'messaging#poll'
  get 'convo/:id' => 'messaging#show_conversation'
  get 'convo' => 'messaging#index'

  get 'mercury/modals/media' => 'images#media_modal'
  get 'mercury/modals/htmleditor.html' => 'utility#mercury_html'
  get 'mercury/images' => 'images#index'
  match 'mercury/images/browse' => 'images#index'
  put 'mercury/images/:id' => 'images#update'
  post 'mercury/images' => 'images#create'
  match 'mercury/links' => 'links#index'
  scope '/mercury' do
          match ':type/:resource' => "mercury#resource"
          match 'snippets/:name/options' => "mercury#snippet_options"
          match 'snippets/:name/preview' => "mercury#snippet_preview"
  end
 
  get "menus/new/:mode" => 'menu#new' 
  get "menus" => 'menu#index'
  put "menu" => 'menu#create'
  get "menu/:id" => "menu#show"
  match "menu/:id/add" => "menu#add", :only=>[:put, :post]
  post "menu/:id/move" => "menu#move"
  get "menu/:id/promote/:item_id/:parent_id" => "menu#promote"
  delete "menu/item/:id" => "menu#delete_item"
  delete "menu/:id" => "menu#delete"
  get "menu/:id/edit/:item_id" => "menu#edit"
  
  put "asset/:id/tags" => 'asset#tags'
  put "asset/:id" => 'asset#update'
  delete "asset/:id" => "asset#delete"
#  get "admin/asset/:id" => "asset#show" ???? not sure we need this???
  get "asset/:id" => "asset#show"
  post "assets" => "asset#create"
  match "assets" => "asset#index"
  get "file/:id/:code/:name" => "asset#get"

  get "/db/content/analyse/:id" => "admin/content#analyse"
  get "/db/content/match/:id" => "admin/content#match"
  get "category/browse" => 'category#browse'
  post "category/move" => 'category#move'
  post "category/delete/:id" => 'category#delete'  
  post "category/rename/:id" => 'category#rename'  
  post "category/new/:parent_id" => 'category#new'
  post "category/:id/public/:public" => 'category#permission_public'
  post "category/:id/permissions/subs" => 'category#permission_sub'
  post "category/:id/permission/:group_id/:mode/:granted" => 'category#permission'
  get "category/:id/permissions" => 'category#permissions'

  # this is only needed to give friendly URL's - we don't actually respond to the requests using this route
  resources :asset # DO WE NEED THIS???

  match 'blocks/:id/options' => "blocks#options"
  get 'blocks/:id/preview' => "blocks#preview"
  get 'blocks/:id/render' => "blocks#preview"
  get 'blocks/:name/instance' => 'blocks#preview_by_name'
  post 'blocks/:id/preview/:page_id' => "blocks#store"
  get 'blocks/:page_id/:mercury_id' => 'blocks#show'
  get 'blocks/:page_id' => 'blocks#index'

  get 'admin/formats' => 'utility#snippet_list'
  get 'admin/format/:id' => 'admin/snippet#fetch'

  get 'admin/block_instance/new/:id' => 'admin/block_instance#create'
  get 'admin/block_instances' => 'admin/block_instance#index'
  get 'admin/block_instance/:id/edit' => 'admin/block_instance#edit'
  get 'admin/block_instance/:id' => 'admin/block_instance#show'
  post 'admin/block_instance/:id/edit' => 'admin/block_instance#update'

  get 'admin/todo/test' => 'admin/todo#test'

  get '/admin/user/profile/html/:mode' => 'admin/user#generate_profile_html'
  delete 'user/profile/:id' => 'user#remove_profile_attribute'  
  post 'user/profile' => 'user#update'
  match 'user/preferences' => 'user#preferences', :only=>[:get, :put]
  get 'user/profile/edit' => 'user#edit_profile'
  get 'user/profile/:id' => 'user#user_profile'
  get 'user/profile' => 'user#profile'
  put 'admin/user/:id/password' => 'admin/user#password'
  post 'admin/user/:id/add_note' => 'admin/user#add_note'
  delete 'admin/users/attribute/:id' => 'admin/user#destroy_attribute'
  get 'admin/users/attribute/:id' => 'admin/user#attribute'
  post 'admin/users/attribute/:id' => 'admin/user#update_attribute'
  match 'admin/users/attributes' => 'admin/user#attributes', :only=>[:get, :post]
 
  get "admin/snippet/:id/fetch" => 'admin/snippet#fetch' 
  post 'admin/user/help_mode' => 'admin/user#help_mode'
  match 'admin/user/:id/email' => 'admin/user#email', :only=>[:get, :post]
  post 'admin/user/:id/become' => 'admin/user#become'
  post 'admin/user/attribute' => 'admin/user#create_attribute'
  get 'admin/user/:id' => 'admin/user#view'
  put 'admin/user/:id' => 'admin/user#update'
  post 'admin/user/:id/group/:group_id' => 'admin/user#add_user_to_group'
  delete 'admin/user/:id/group/:group_id' => 'admin/user#remove_user_from_group'
  put 'admin/user/:id/attribute/:attribute_id' => 'admin/user#attribute_value'
  match 'admin/user' => 'admin/user#index', :only=>[:get, :post]
  match 'admin/users' => 'admin/user#index', :only=>[:get, :post]

  get 'admin/groups' => 'admin/group#index'
  put 'admin/group' => 'admin/group#create'
  delete 'admin/group/:id' => 'admin/group#destroy'

  get 'admin/mailchimp/import' => 'admin/mailchimp#import'
  get 'admin/mailchimp' => 'admin/mailchimp#index'
  match 'api/mailchimp' => 'admin/mailchimp#callback'

  post 'admin/newsletters/fetch/:id' => 'admin/newsletter#fetch'
  match  'admin/newsletters/fetch' => 'admin/newsletter#fetch'
  post  'admin/newsletters/email/:id' => 'admin/newsletter#email'
  post  'admin/newsletters/send/:id' => 'admin/newsletter#send_now'
  get  'admin/newsletters/preview/:id' => 'admin/newsletter#preview'
  get  'admin/newsletters/:id' => 'admin/newsletter#history'
  get  'admin/newsletters' => 'admin/newsletter#index'

  post 'admin/dashboard/reindex' => 'admin/dashboard#reindex'
  get 'admin/dashboard/search' => 'admin/dashboard#search'
  get 'admin/dashboard/activity' => 'admin/dashboard#activity'
  match 'admin/dashboard/build_system' => 'admin/dashboard#build_system'
  post 'admin/dashboard/zap' => 'admin/dashboard#zap'

  match 'admin/dashboard/recent_activity' => 'admin/dashboard#recent_activity'
  match 'admin/dashboard/recent_pages' => 'admin/dashboard#recent_pages'
  get 'admin/dashboard' => 'admin/dashboard#index'
  post 'admin/todo' => 'admin/todo#create'
  get 'admin/todo' => 'admin/todo#search'
  match 'admin/todo/search' => 'admin/todo#search'
  post 'admin/todo/mark/:id/:mode' => 'admin/todo#mark'

  put 'admin/preference/update' => 'admin/preference#update'
  match 'admin/preference' => 'admin/preference#index', :only=>[:get, :post]

  match "forums/zap/:x" => proc { [404, {}, ['']] }
  get "forums/test" => 'forum#test'
  get "forums/moderate" => 'forum#moderate'
  post "admin/forums/topic/:id/:attr/:value" => "admin/topic#make"
  get "admin/forums/topic/:id/edit" => 'admin/topic#edit'
  get "admin/forums/topic/:id" => 'admin/topic#show'
  put "admin/forums/topic/:id" => 'admin/topic#update'
  delete "admin/forums/topic/:id" => 'admin/topic#destroy'
  post 'admin/forums/category/:id/delete' => 'admin/forum#delete_category'
  post "admin/forums/category/:id" => 'admin/forum#update_category'
  get "admin/forums/category/:id" => 'admin/forum#edit_category'
  post 'admin/forums/create_topic' => 'admin/forum#create_topic'
  post 'admin/forums/create_category' => 'admin/forum#create_category'
  get 'admin/forums' => 'admin/forum#index'

  post 'utility/add_comment' => 'utility#add_comment'
  post "user/check_display_name" => 'user#check_display_name'
  post 'utility/markdown_preview' => 'utility#markdown_preview'
  post 'forums/post/preview' => 'forum#preview'
  get 'forums/category_topic_list/:id' => 'forum#category_topic_list'
  post "forum/post/:id/rate/:score" => 'forum#rate_post'
  post "forum/display_name" => 'user#display_name'
  match "forums/report/:id" => 'forum#report'
  match "forums/search" => 'forum#search'
  get "forums/comments/:id" => 'forum#comments'
  delete "forums/post/:id/:delete" => 'forum#delete_post'
  post "forums/thread_comment/:id" => 'forum#thread_comment'
  post "forums/topic_comment/:id" => 'forum#topic_comment'
  post "forums/page/:page_id" => 'forum#create_page_thread'
  post "forums/move_thread/:thread_id/:topic_id" => "forum#move_thread"
  get "forums/recent_posts" => "forum#recent_posts"
  get "forums/recent" => "forum#recent"
  get "forums/favourites" => "forum#favourites"
  get "forums/threads_im_on" => "forum#im_on"
  post "forums/:name/:id" => 'forum#add_post'
  post "forums/thread/:id/favourite" => 'forum#favourite_thread'
  post "forums/thread/:id/unfavourite" => 'forum#unfavourite_thread'
  get "forums/post/:id" => 'forum#fetch_raw'
  put "forums/post/:id" => 'forum#edit_post'
  put "forums/thread/:id" => 'forum#edit_thread'
  delete "forums/thread/:id" => 'forum#delete_thread' 
  post "forums/lock/:id/:lock" => 'forum#lock_thread' 
  get "forums/category/:category" => 'forum#index'
  get "forums/:topic/latest/:id" => "forum#thread_last_unread"
  get "forums/:topic/:id" => 'forum#thread'
  get "forums/:topic" => 'forum#topic_index'
  post "forums/:topic" => 'forum#create_thread'
  get "forums" => 'forum#index'

  get "down_for_maintenance" => 'utility#down_for_maintenance'
  get 'utility/user_email_to_ids' => 'utility#user_email_to_ids'
  get "utility/design_history/:id" => 'utility#design_history'
  post 'utility/display_name_check' => 'utility#display_name_check'
  get "utility/menu" => 'utility#menu'
  post "utility/fetch_rss" => "utility#fetch_rss"

  resources :category
  post "category/select_options" => "category#select_options"

  get 'pages/editor_trial' => 'pages#editor_trial'
  get 'page/:id/possible_terms' => 'pages#possible_terms'
  get 'pages/zoom' => 'pages#zoom'
  post 'page/unique' => 'pages#unique'
  get 'page/info' => 'pages#info'
  match 'page/:id/page_template' => 'pages#page_template', :only=>[:get, :post]
  post 'page/:id/copy' => 'pages#copy'
  delete 'page/:id/terms/:term_id' => 'pages#terms'
  match '/page/:id/terms' => 'pages#terms'
  delete 'page/:id/draft' => 'pages#destroy_draft'
  post 'page/:id/publish_draft' => 'pages#publish_draft'
  post 'page/:id/make_draft' => 'pages#make_draft'
  post 'page/:id/make_home' => 'pages#make_home'
  delete 'page/:id/auto_saves/:what' => 'pages#auto_save_delete'
  match 'page/:id/info' => 'pages#info', :only=>[:get, :post]
  match 'page/:id/edit' => 'pages#edit', :only=>[:get, :post]
  delete 'page/:id' => 'pages#destroy'
  match 'page/:id/delete' => 'pages#destroy', :only=>[:delete, :post]
  match 'page/:id/undelete' => 'pages#undelete', :only=>[:delete, :post]
  match "pages/:id/favourite" => "pages#favourite", :only=>[:post, :delete]
  post "pages/notification/:id/:mode" => 'pages#notification'
  post "pages/autosave/:url_id" => 'pages#autosave'
  post 'page/:id/add_note' => 'pages#add_note'
  get 'page/:id/notes' => 'pages#notes'
  get 'page/:id/content/:content_id/edit' => 'pages#content_edit'
  post 'page/:id/content/:content_id' => 'pages#content_update'
  get 'page/:id/contents' => 'pages#contents' 
  get 'page/:id/content/:content_id/field' => 'pages#show_content' 
  get 'page/:id/content/:content_id/block' => 'pages#show_block_content' 
  get 'page/:id/menu/:menu_id' => 'pages#menu'
  get 'pages/status/:status_id' => 'pages#index'
  post 'page/stub/rename/:id' => 'pages#stub_rename'
  post 'page/stub/:cat_id' => 'pages#stub'
  get 'page/new' => 'pages#new'
  match 'pages/search' => 'pages#search'

  resources :pages
  
  get 'redir/:id' => 'pages#redir'
  get 'utility/filebrowser' => 'utility#filebrowser'
  get 'kit/cookie_text' => 'pages#cookie_text'
  get "view/:view_name" => 'view#show'
  get "error(/:id)" => 'error#application'

  get "/system/:id/:type1/:type2/:n1/:n2/:n3/:n4/:code/:size/*file" => 'kit#not_found_404'

  post '*url' => 'pages#save'
  get '*url', :controller=>"pages", :action=>"show", :constraints=>{:url => /(?<!\.gif|\.png|\.jpg|\.jpeg|\.pdf|\.jpeg)$/i}
  
  root :to=>"pages#show"
end

