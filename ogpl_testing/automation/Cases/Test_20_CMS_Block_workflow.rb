# CMS BLOCK WORKFLOW

require 'rubygems'
#Load WATIR
require 'fileutils'
require 'lib/selenium_support'
# Load WIN32OLE library
require 'win32ole'
require 'Win32API'
#Load the win32 library
require 'win32/clipboard'
include Win32
require 'InputRepository/Test_20_CMS_Block_workflow_input.rb'
require 'InputRepository/Config.rb'
require 'lib/NIC_Lib.rb'

describe "CMS Block workflow (Creation/Approval/Publishing)" do

  before(:all) do
      `Taskkill /IM firefox.exe /F`
      $obj = NIC_Lib.new
      @browser1 = $obj.CMS_login($CMS_Admin_User_Email,$CMS_Admin_User_Passwd)
      @browser2 = $obj.CMS_login($CMS_moderator_email,$CMS_moderator_passwd)
      @browser3 = $obj.CMS_login($CMS_publisher_email,$CMS_publisher_passwd)
      #@browser4 = $obj.CMS_login($CMS_superadmin_uname,$CMS_superadmin_passwd)
      @browser5 = $obj.CMS_login($CMS_content_creater_email,$CMS_content_creater_passwd)
  end


#To Login As CMS_Admin
  it "Validation check for Title of the Block" do

        @browser1.goto("#{$Site_URL}node/add/block")
        @browser1.text_field(:id, "edit-field-instructions-0-value").set($instruction)
        @browser1.frame(:title => 'Rich Text AreaPress ALT-F10 for toolbar. Press ALT-0 for help').send_keys "#{$body}"
        @browser1.select_list(:id, "edit-field-content-creator-uid-uid").select($CMS_content_creater_email)
        @browser1.select_list(:id, "edit-field-moderator-uid-uid").select($CMS_moderator_email)
        @browser1.text_field(:id,"edit-field-expiry-date-0-value-datepicker-popup-0").set($date)
        @browser1.browser.text_field(:id, "edit-field-no-ofdays-0-value").set($days)
        @browser1.button(:value,"Save").click
        sleep 3
        @browser1.text.should include('Title field is required')
        puts "Validation completed"

   end

   it "Check preview" do

      $ext = Time.now
      $ext = $ext.to_s
      $ext = $ext.slice(0..18)
      $ext = $ext.gsub(" ", "_")
      $block_title = "#{$title}" + "_" + "#{$ext}"
      puts $block_title
      @browser1.text_field(:id, "edit-title").set($block_title)
      @browser1.browser.button(:value,"Preview").click
      @browser1.text.should include($block_title)
      puts "Preview completed"
   end

   it "Save Block" do
      @browser1.button(:value,"Save").click
      sleep 2
      @browser1.text.should include("Block #{$block_title} has been created")
      puts "Save completed"
   end

   it "Edit Block" do
      $revised_inst = "#{$instruction}" + "" + "Revised"
      @browser1.link(:text, "Edit").click
      sleep 2
      $url = @browser1.url
      puts $url
      $node_val = /node\/(\d+)\//.match($url)
      puts $node_val
      $node_val = $node_val.to_s
      $node_len = $node_val.length
      puts $node_len
      $node_val = $node_val.slice(5..$node_len-2)
      puts $node_val

      @browser1.text_field(:id, "edit-field-instructions-0-value").set($revised_inst)
      @browser1.button(:value,"Save").click
      sleep 2
      @browser1.text.should include("#{$revised_inst}")
      puts "Edit completed"

   end

   it "Send to moderator for approval" do
      @browser5.link(:text, "Home").click
      sleep 3
      @browser5.select_list(:id, "edit-type").clear
      @browser5.select_list(:id, "edit-sid").clear
      sleep 2
      @browser5.select_list(:id, "edit-type").select("Block")
      @browser5.select_list(:id, "edit-sid").select("Create/Edit Content")
      @browser5.button(:value,"Apply").click
      sleep 10
      @browser5.text.should include($block_title)
      #@browser1.link(:text, "Submit").click
      @browser5.link(:href,"#{$Site_URL}node/#{$node_val}/workflow?workflow_state=18&destination=").click
      sleep 10
      @browser5.radio(:id, "edit-workflow-18").set
      @browser5.text_field(:id, "edit-workflow-comment").set($com_to_mod_by_conc)
      @browser5.button(:value,"Submit").click
      sleep 2
      @browser5.link(:text, "Home").click
      @browser5.select_list(:id, "edit-type").clear
      @browser5.select_list(:id, "edit-sid").clear
      sleep 2
      @browser5.select_list(:id, "edit-type").select("Block")
      @browser5.select_list(:id, "edit-sid").select("Create/Edit Content")
      @browser5.button(:value,"Apply").click
      sleep 10
      @browser5.text.should_not include($block_title)
      @browser5.link(:text, "Home").click
      @browser5.select_list(:id, "edit-type").clear
      @browser5.select_list(:id, "edit-sid").clear
      sleep 2
      @browser5.select_list(:id, "edit-type").select("Block")
      @browser5.select_list(:id, "edit-sid").select("Moderator Review")
      @browser5.button(:value,"Apply").click
      sleep 10
      @browser5.text.should include($block_title)
      puts "Send to moderator for approval completed"
   end


  it "Send back to workflow by Moderator" do
      @browser2.refresh
      @browser2.link(:text, "Home").click
      sleep 3
      @browser2.select_list(:id, "edit-type").clear
      @browser2.select_list(:id, "edit-sid").clear
      sleep 2
      @browser2.select_list(:id, "edit-type").select("Block")
      @browser2.select_list(:id, "edit-sid").select("Moderator Review")
      @browser2.button(:value,"Apply").click
      sleep 10
      @browser2.text.should include($block_title)
      @browser2.link(:href,"#{$Site_URL}node/#{$node_val}/workflow?workflow_state=17&destination=").click
      sleep 10
      @browser2.radio(:id, "edit-workflow-17").set
      @browser2.text_field(:id, "edit-workflow-comment").set($com_to_conc_by_mod)
      @browser2.button(:value,"Submit").click
      @browser2.link(:text, "Home").click
      sleep 3
      @browser2.select_list(:id, "edit-type").clear
      @browser2.select_list(:id, "edit-sid").clear
      sleep 2
      @browser2.select_list(:id, "edit-type").select("Block")
      @browser2.select_list(:id, "edit-sid").select("Moderator Review")
      @browser2.button(:value,"Apply").click
      sleep 10
      @browser2.text.should_not include($block_title)
      @browser2.select_list(:id, "edit-type").clear
      @browser2.select_list(:id, "edit-sid").clear
      sleep 2
      @browser2.select_list(:id, "edit-type").select("Block")
      @browser2.select_list(:id, "edit-sid").select("Create/Edit Content")
      @browser2.button(:value,"Apply").click
      sleep 10
      @browser2.text.should include($block_title)
      # Go to Content creater session
      @browser5.refresh
      @browser5.link(:text, "Home").click
      sleep 3
      @browser5.select_list(:id, "edit-type").clear
      @browser5.select_list(:id, "edit-sid").clear
      sleep 2
      @browser5.select_list(:id, "edit-type").select("Block")
      @browser5.select_list(:id, "edit-sid").select("Create/Edit Content")
      @browser5.button(:value,"Apply").click
      sleep 10
      @browser5.text.should include($block_title)
      #@browser1.link(:text, "Submit").click
      @browser5.link(:href,"#{$Site_URL}node/#{$node_val}/workflow?workflow_state=18&destination=").click
      sleep 10
      @browser5.radio(:id, "edit-workflow-18").set
      @browser5.text_field(:id, "edit-workflow-comment").set($com_2_to_mod_by_conc)
      sleep 2
      @browser5.button(:value,"Submit").click
      sleep 2
      puts "Send back to workflow by moderator completed"
  end

  it "Send to publisher for approval" do
      @browser2.refresh
      @browser2.link(:text, "Home").click
      sleep 3
      @browser2.select_list(:id, "edit-type").clear
      @browser2.select_list(:id, "edit-sid").clear
      sleep 2
      @browser2.select_list(:id, "edit-type").select("Block")
      @browser2.select_list(:id, "edit-sid").select("Moderator Review")
      @browser2.button(:value,"Apply").click
      sleep 10
      @browser2.text.should include($block_title)
      @browser2.link(:href,"#{$Site_URL}node/#{$node_val}/workflow?workflow_state=22&destination=").click
      sleep 10
      @browser2.radio(:id, "edit-workflow-22").set
      @browser2.text_field(:id, "edit-workflow-comment").set($com_to_pub_by_mod)
      @browser2.button(:value,"Submit").click
      sleep 2
      @browser2.link(:text, "Home").click
      sleep 3
      @browser2.select_list(:id, "edit-type").clear
      @browser2.select_list(:id, "edit-sid").clear
      sleep 2
      @browser2.select_list(:id, "edit-type").select("Block")
      @browser2.select_list(:id, "edit-sid").select("Moderator Review")
      @browser2.button(:value,"Apply").click
      sleep 10
      @browser2.text.should_not include($block_title)
      @browser2.select_list(:id, "edit-type").clear
      @browser2.select_list(:id, "edit-sid").clear
      sleep 2
      @browser2.select_list(:id, "edit-type").select("Block")
      @browser2.select_list(:id, "edit-sid").select("Publisher Review")
      @browser2.button(:value,"Apply").click
      sleep 10
      @browser2.text.should include($block_title)
      @browser3.refresh
      @browser3.link(:text, "Home").click
      sleep 3
      @browser3.select_list(:id, "edit-type").clear
      @browser3.select_list(:id, "edit-sid").clear
      sleep 2
      @browser3.select_list(:id, "edit-type").select("Block")
      @browser3.select_list(:id, "edit-sid").select("Publisher Review")
      @browser3.button(:value,"Apply").click
      sleep 10
      @browser3.text.should include($block_title)
      puts "Send to Publisher for approval"
  end

  it "Send back to workflow by Publisher" do
      @browser3.refresh
      @browser3.link(:text, "Home").click
      sleep 3
      @browser3.select_list(:id, "edit-type").clear
      @browser3.select_list(:id, "edit-sid").clear
      sleep 2
      @browser3.select_list(:id, "edit-type").select("Block")
      @browser3.select_list(:id, "edit-sid").select("Publisher Review")
      @browser3.button(:value,"Apply").click
      sleep 2
      @browser3.link(:href,"#{$Site_URL}node/#{$node_val}/workflow?workflow_state=18&destination=").click
      sleep 2
      @browser3.radio(:id, "edit-workflow-18").set
      @browser3.text_field(:id, "edit-workflow-comment").set($com_to_mod_by_pub)
      @browser3.button(:value,"Submit").click
      @browser3.link(:text, "Home").click
      sleep 3
      @browser3.select_list(:id, "edit-type").clear
      @browser3.select_list(:id, "edit-sid").clear
      sleep 2
      @browser3.select_list(:id, "edit-type").select("Block")
      @browser3.select_list(:id, "edit-sid").select("Publisher Review")
      @browser3.button(:value,"Apply").click
      sleep 10
      @browser3.text.should_not include($block_title)
      @browser3.select_list(:id, "edit-type").clear
      @browser3.select_list(:id, "edit-sid").clear
      sleep 2
      @browser3.select_list(:id, "edit-type").select("Block")
      @browser3.select_list(:id, "edit-sid").select("Moderator Review")
      @browser3.button(:value,"Apply").click
      sleep 10
      @browser3.text.should include($block_title)
      # Go to Moderator session
      @browser2.refresh
      @browser2.link(:text, "Home").click
      sleep 3
      @browser2.select_list(:id, "edit-type").clear
      @browser2.select_list(:id, "edit-sid").clear
      sleep 2
      @browser2.select_list(:id, "edit-type").select("Block")
      @browser2.select_list(:id, "edit-sid").select("Moderator Review")
      @browser2.button(:value,"Apply").click
      sleep 10
      @browser2.text.should include($block_title)
      #@browser1.link(:text, "Submit").click
      @browser2.link(:href,"#{$Site_URL}node/#{$node_val}/workflow?workflow_state=22&destination=").click
      sleep 10
      @browser2.radio(:id, "edit-workflow-22").set
      @browser2.text_field(:id, "edit-workflow-comment").set($com_2_to_pub_by_mod)
      sleep 2
      @browser2.button(:value,"Submit").click
      sleep 2
      puts "Send back to workflow by publisher completed"
  end

  it "Publish Block" do
      @browser3.refresh
      @browser3.link(:text, "Home").click
      sleep 3
      @browser3.select_list(:id, "edit-type").clear
      @browser3.select_list(:id, "edit-sid").clear
      sleep 2
      @browser3.select_list(:id, "edit-type").select("Block")
      @browser3.select_list(:id, "edit-sid").select("Publisher Review")
      @browser3.button(:value,"Apply").click
      sleep 10
      @browser3.text.should include($block_title)
      @browser3.link(:href,"#{$Site_URL}node/#{$node_val}/workflow?workflow_state=19&destination=").click
      sleep 10
      @browser3.radio(:id, "edit-workflow-19").set
      @browser3.text_field(:id, "edit-workflow-comment").set($com_published)
      sleep 2
      @browser3.button(:value,"Submit").click
      sleep 2
      @browser3.text.should include("Revision has been published")
      @browser3.link(:text, "Home").click
      sleep 3
      @browser3.select_list(:id, "edit-type").clear
      @browser3.select_list(:id, "edit-sid").clear
      sleep 2
      @browser3.select_list(:id, "edit-type").select("Block")
      @browser3.select_list(:id, "edit-sid").select("Published")
      @browser3.button(:value,"Apply").click
      sleep 10
      @browser3.text.should include($block_title)
      puts "Publish Block completed"
  end

  it "Verify workflow history" do
      @browser3.link(:href,"#{$Site_URL}node/#{$node_val}/workflow?workflow_state=17&destination=").click
      sleep 10
      @browser3.text.should include($com_to_mod_by_conc)
      @browser3.text.should include($com_to_conc_by_mod)
      @browser3.text.should include($com_to_pub_by_mod)
      @browser3.text.should include($com_published)
      @browser3.text.should include($com_2_to_mod_by_conc)
      @browser3.text.should include($com_2_to_pub_by_mod)
      @browser3.text.should include($com_to_mod_by_pub)
      puts "Verify workflow history completed"
  end

  it "Manage Block Layout" do
      @browser1.goto("#{$Site_URL}admin/build/block/list")
      sleep 45
      @browser1.select_list(:id,"edit-nodeblock-#{$node_val}-region").select($region)
      sleep 3
      @browser1.button(:value,"Save blocks").click
      sleep 2
      puts "Manage block layout completed"
  end

  it "Verify block on front end" do
      driver = Selenium::WebDriver.for :firefox, :profile => "Selenium"
      @browser = Watir::Browser.new driver
      @browser.goto("#{$Site_URL}")
      @browser.text.should include($block_title)
      @browser.close
      puts "Verify block on frontend completed"
  end
=begin
  it "Delete Block" do
      @browser4.refresh
      @browser4.goto("#{$Site_URL}admin/content/node")
      sleep 3
      @browser4.select_list(:id, "edit-type").select("Block")
      @browser4.button(:value,"Filter").click
      sleep 3
      @browser4.checkbox(:id, "edit-nodes-#{$node_val}").set
      
      @browser4.select_list(:id, "edit-operation").select("Delete")
      @browser4.button(:value,"Update").click
      sleep 3
      #@browser4.text.should include($block_title)
      @browser4.button(:value,"Delete all").click
      #@browser4.text.should include("Block #{$block_title} has been deleted")
      puts "Delete Block completed"

  end

  it "Verify Block not displayed on front end after deletion" do
      driver = Selenium::WebDriver.for :firefox, :profile => "Selenium"
      @browser = Watir::Browser.new driver
      @browser.goto("#{$Site_URL}")
      @browser.text.should include($block_title)
      @browser.close
      puts "Verify Block not displayed on front end after deletion completed"
  end
=end
  after(:all) do
        @browser1.link(:text,"Log Out").click
        @browser2.link(:text,"Log Out").click
        @browser3.link(:text,"Log Out").click
        #@browser4.link(:text,"Log Out").click
        @browser5.link(:text,"Log Out").click
        @browser1.close
        @browser2.close
        @browser3.close
        #@browser4.close
        @browser5.close
        `Taskkill /IM firefox.exe /F`
        puts "Test has completed"
  end

end
