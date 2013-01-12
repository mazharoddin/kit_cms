require 'rubygems'
require 'watir-webdriver'

profile = Selenium::WebDriver::Chrome::Profile.new
profile['download.prompt_for_download'] = false

host = "http://localhost:3000"

b = Watir::Browser.new :chrome, :profile=>profile

b.goto "#{host}/users/sign_out"

if b.text.include? "cookie"
  b.button(:name=>"grant").click
end

b.goto "#{host}/group-b-read/sub-group-b-read/xx/test"
unless b.text.include? "Sign in"
  puts "Didn't get prompted to sign in"
  exit -1
end

b.text_field(:name=>'user[email]').set 'kit@dsc.net'
b.text_field(:name=>'user[password]').set 'kit101'
b.button(:name=>'commit').click

unless b.text.include? "Signed in successfully"
  puts "Sign in failed"
  exit -1
end

b.goto "#{host}/db"
b.goto "#{host}/admin/users"
b.text_field(:id=>'search_for').set 'hotmail'
b.link(:id=>'submit[search]').click

unless b.text.include? "Showing 50 of 101"
  puts "Search failed"
  exit -1
end

b.goto "#{host}/admin/users?for=hotmail&page=2&parameter=&submit_button=search&user_id=&value="
#b.link(:text=>"2").click

unless b.text.include? "gerathome@hotmail"
  puts "Search pagination failed"
  exit -1
end

b.link(:text=>"gerathome@hotmail").click

unless b.text.include? "Add to other groups"
  puts "User failed"
  exit -1
end

b.link(:text=>"Add to other groups").click
b.link(:text=>"ddddd").click

b.goto("#{host}/pages")
b.goto("#{host}/page/10/info")
b.link(:text=>"Show Access Permissions").click
b.link(:text=>"Change Permissions For This Category").click
b.link(:text=>"ddddd").click

b.goto("#{host}/users/sign_out")

b.goto "#{host}/group-b-read/sub-group-b-read/xx/test"


b.text_field(:name=>'user[email]').set 'gerathome@hotmail'
b.text_field(:name=>'user[password]').set 'asdfasdf'
b.button(:name=>'commit').click


exit 0


