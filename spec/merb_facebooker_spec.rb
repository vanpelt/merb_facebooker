require File.dirname(__FILE__) + '/spec_helper'

Merb::Router.prepare do |r|
  r.match('/').to(:controller => 'facebook_helpers', :action =>'index')
end

class FacebookerHelpers < Merb::Controller
  def index
    "hi"
  end
end

Merb::Config.use { |c|
  c[:framework]           = {},
  c[:session_store]       = 'none',
  c[:exception_details]   = true
}

# ok lets start with the helpers and go from there
describe "Controller With Facebooker Helpers" do
  before(:all) do
    @controller = FacebookerHelpers.new(fake_request)
  end
  
  describe "calling fb_profile(@user, options) given user has facebook_id=1234" do
    before(:all) do
      @user = stub("User", :facebook_id => 1234)
    end
    
    it "should be able to call" do
      @controller.should respond_to(:fb_profile_pic)
    end
  
    it "should equal <fb:profile-pic uid='1234' /> when calling with @user" do
      @controller.fb_profile_pic(@user).should == "<fb:profile-pic uid=\"1234\"/>"
    end
  
    it "should equal <fb:profile-pic uid='1234' size='small'/> when calling with @user, :size => :small" do
      @controller.fb_profile_pic(@user, :size => :small).should == "<fb:profile-pic uid=\"1234\" size=\"small\"/>"
    end
  
    it "should raise Argument Error is the incorrect size is given when calling @user, :size => :egg" do
      lambda{@controller.fb_profile_pic(@user, :size => :egg)}.should raise_error
    end
  end
  
  
  describe "calling fb_photo where given photo has an photo_id = 1234" do
    before(:all) do
      @photo = stub("Photo", :photo_id => 1234)
    end
    
    it "should be able to call" do
      @controller.should respond_to(:fb_photo)
    end
    
    it "should equal <fb:photo pid=\"1234\" /> with parameter @photo" do
      @photo.stub!(:photo_id).and_return(1234) # DONT ASK
      @controller.fb_photo(@photo).should == "<fb:photo pid=\"1234\"/>"
    end
  end
  
end