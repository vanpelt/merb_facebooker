$TESTING=true
$:.push File.join(File.dirname(__FILE__), '..', 'lib')

# going to be specing for Merb so lets just do that shall we
require 'rubygems'
require 'merb-core'
require 'merb_facebooker'
require 'spec'

Merb.start_environment(:testing => true, :adapter => 'runner', :environment => ENV['MERB_ENV'] || 'test')

Spec::Runner.configure do |config|
  config.include(Merb::Test::ViewHelper)
  config.include(Merb::Test::RouteHelper)
  config.include(Merb::Test::ControllerHelper)
end