# make sure we're running inside Merb
require 'merb_facebooker/controller'
require 'merb_facebooker/helpers'

if defined?(Merb::Plugins)
  dependency "facebooker"
  dependency "merb_helpers"
  
  # Merb gives you a Merb::Plugins.config hash...feel free to put your stuff in your piece of it
  facebook_config = "#{Merb.root}/config/facebooker.yml"
  if File.exist?(facebook_config)
    Merb::Plugins.config[:merb_facebooker] = YAML.load_file(facebook_config)[Merb.environment]
    ENV['FACEBOOK_API_KEY'] = Merb::Plugins.config[:merb_facebooker]['api_key']
    ENV['FACEBOOK_SECRET_KEY'] = Merb::Plugins.config[:merb_facebooker]['secret_key']
    ENV['FACEBOOKER_RELATIVE_URL_ROOT'] = Merb::Plugins.config[:merb_facebooker]['canvas_page_name']
    #ActionController::Base.asset_host = FACEBOOKER['callback_url']
  end
  
  Merb.add_mime_type(:fbml,  :to_fbml,  %w[application/fbml text/fbml], :Encoding => "UTF-8")
  Merb::Request.http_method_overrides.push(
    proc { |c| c.params[:fb_sig_request_method].clone }
  )
  
  Merb::BootLoader.before_app_loads do
    Merb::Controller.send(:include, Facebooker::Merb::Controller) 
    Merb::Controller.send(:include, Facebooker::Merb::Helpers)
    # require code that must be loaded before the application
  end
  
  Merb::BootLoader.after_app_loads do
    # code that can be required after the application loads
  end
  
  Merb::Plugins.add_rakefiles "merb_facebooker/merbtasks"
end
