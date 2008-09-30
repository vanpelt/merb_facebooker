module Facebooker
  module Merb
    module Controller
      
      def self.included(controller)
        controller.extend(ClassMethods)
        controller.before :set_fbml_format
      end
      
      #
      # Just returns the @facebook_session instance variable
      # 
      def facebook_session
        @facebook_session
      end
      
      #
      # Tries to secure the facebook_session, if it is not secured already, it tries to secure it 
      # via the request parameter 'auth_token', if that doesn't work, it tries to use the parameters 
      # from facebook (this could be in the request or via cookies [cookies in case of FBConnect]).
      #
      def set_facebook_session
        session_set = session_already_secured? || secure_with_token! || secure_with_facebook_params!
        if session_set
          capture_facebook_friends_if_available! 
          Session.current = facebook_session
        end
        session_set
      end
      
      #
      # initializes the @facebook_params instance using the method verified_facebook_params
      #
      def facebook_params
        @facebook_params ||= verified_facebook_params
      end      
      
      private
      
      #
      # Ensures there is an existing facebook session, and if so, it ask if it is secured.
      #
      def session_already_secured?
        (@facebook_session = session[:facebook_session]) && session[:facebook_session].secured?
      end
      
      # 
      # Use auth_token parameter for the creation of a facebook_session 
      #
      def secure_with_token!
        if params['auth_token']
          @facebook_session = new_facebook_session
          @facebook_session.auth_token = params['auth_token']
          @facebook_session.secure!
          session[:facebook_session] = @facebook_session
        end
      end
      
      #
      # If the request is made from a facebook canvas, then it checks for the session key and the user
      # from the facebook_params hash key
      #
      def secure_with_facebook_params!
        debugger
        return if !request_is_for_a_facebook_canvas? && !using_facebook_connect?
        
        if ['user', 'session_key'].all? {|element| facebook_params[element]}
          @facebook_session = new_facebook_session
          @facebook_session.secure_with!(facebook_params['session_key'], facebook_params['user'], facebook_params['expires'])
          session[:facebook_session] = @facebook_session
        end
      end
      
      #
      # Resets the facebook_session
      #
      def create_new_facebook_session_and_redirect!
        session[:facebook_session] = new_facebook_session
        throw :halt, redirect(session[:facebook_session].login_url) unless @installation_required 
      end
      
      #
      #  Facebooker Session Factory
      #
      def new_facebook_session
        Facebooker::Session.create(Facebooker::Session.api_key, Facebooker::Session.secret_key)
      end
      
      def capture_facebook_friends_if_available!
        return unless request_is_for_a_facebook_canvas?
        if friends = facebook_params['friends']
          facebook_session.user.friends = friends.map do |friend_uid|
            User.new(friend_uid, facebook_session)
          end
        end
      end
            
      #
      # Helper method (acts as ActiveSupport's blank? method)
      #
      def blank?(value)
        (value == '0' || value.nil? || value == '')        
      end

      #
      # Get all the parameters from facebook via the request or cookies...
      # (Cookies have more presedence)
      #
      def verified_facebook_params
        if !request.cookies[Facebooker::Session.api_key].blank?
          facebook_sig_params = request.cookies.inject({}) do |collection, pair|
            if pair.first =~ /^#{Facebooker::Session.api_key}_(.+)/
              collection[$1] = pair.last
            end
            collection
          end
        else
          # same ol...
          facebook_sig_params = params.inject({}) do |collection, pair|
            collection[pair.first.sub(/^fb_sig_/, '')] = pair.last if pair.first[0,7] == 'fb_sig_'
            collection
          end
          verify_signature(facebook_sig_params, params['fb_sig'])
        end
        
        facebook_sig_params.inject(Mash.new) do |collection, pair| 
          collection[pair.first] = facebook_parameter_conversions[pair.first].call(pair.last)
          collection
        end
      end
      
      #
      # Session timeout value
      #
      def earliest_valid_session
        48.hours.ago
      end
      
      
      #
      # Checks if the signature matches the hash made from the parameters (does not apply on FBConnect)
      #
      def verify_signature(facebook_sig_params,expected_signature)
        raw_string = facebook_sig_params.map{ |*args| args.join('=') }.sort.join
        actual_sig = Digest::MD5.hexdigest([raw_string, Facebooker::Session.secret_key].join)
        raise Facebooker::Session::IncorrectSignature if actual_sig != expected_signature
        raise Facebooker::Session::SignatureTooOld if Time.at(facebook_sig_params['time'].to_f) < earliest_valid_session
        true
      end
      
      #
      # Parses the values from facebook_parameters
      #
      def facebook_parameter_conversions
        @facebook_parameter_conversions ||= Hash.new do |hash, key| 
          lambda{|value| value}
        end.merge(
          'time' => lambda{|value| Time.at(value.to_f)},
          'in_canvas' => lambda{|value| !blank?(value)},
          'added' => lambda{|value| !blank?(value)},
          'expires' => lambda{|value| blank?(value) ? nil : Time.at(value.to_f)},
          'friends' => lambda{|value| value.split(/,/)}
        )
      end
      
      #
      # Overwrite of the redirect method, if it is to a canvas, then use an fbml_redirect_tag
      #
      def redirect(*args)
        if request_is_for_a_facebook_canvas?
          fbml_redirect_tag(*args)
        else
          super
        end
      end
      
      def fbml_redirect_tag(url)
        puts url
        "<fb:redirect url=\"#{url}\" />"
      end
      
      def request_is_for_a_facebook_canvas?
        !params['fb_sig_in_canvas'].blank?
      end
      
      def using_facebook_connect?
        !cookies[Facebooker::Session.api_key].blank?
      end
      
      def application_is_installed?
        facebook_params['added']
      end
      
      def ensure_authenticated_to_facebook
        set_facebook_session || create_new_facebook_session_and_redirect!
      end
      
      def ensure_application_is_installed_by_facebook_user
        @installation_required = true
        authenticated_and_installed = ensure_authenticated_to_facebook && application_is_installed? 
        application_is_not_installed_by_facebook_user unless authenticated_and_installed
        authenticated_and_installed
      end
      
      def application_is_not_installed_by_facebook_user
        throw :halt, redirect(session[:facebook_session].install_url)
      end
      
      def set_fbml_format
        params[:format] = "fbml" if request_is_for_a_facebook_canvas?
      end
      
      module ClassMethods
        #
        # Creates a filter which reqires a user to have already authenticated to
        # Facebook before executing actions.  Accepts the same optional options hash which
        # before_filter and after_filter accept.
        def ensure_authenticated_to_facebook(options = {})
          before :ensure_authenticated_to_facebook, options
        end
        
        def ensure_application_is_installed_by_facebook_user(options = {})
          before :ensure_application_is_installed_by_facebook_user, options
        end
      end
    end
  end
end