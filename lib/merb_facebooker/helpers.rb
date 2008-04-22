module Facebooker
  module Merb
    module Helpers
      #const
      VALID_FB_SHARED_PHOTO_SIZES = [:thumb, :small, :normal, :square]
      VALID_FB_PHOTO_SIZES = VALID_FB_SHARED_PHOTO_SIZES      
      VALID_FB_PROFILE_PIC_SIZES = VALID_FB_SHARED_PHOTO_SIZES
      
      VALID_FB_SHARED_ALIGN_VALUES = [:left, :right]
      VALID_FB_PHOTO_ALIGN_VALUES = VALID_FB_SHARED_ALIGN_VALUES
      VALID_FB_TAB_ITEM_ALIGN_VALUES = VALID_FB_SHARED_ALIGN_VALUES

      FB_PHOTO_VALID_OPTION_KEYS = [:uid, :size, :align]
      
      # Create an fb:request-form without a selector
      #
      # The block passed to this tag is used as the content of the form
      #
      # The message param is the name sent to content_for that specifies the body of the message
      #
      # For example,
      #
      #  <% content_for("invite_message") do %>
      #    This gets sent in the invite. <%= fb_req_choice("with a button!",new_poke_path) %>
      #  <% end %>
      #  <% fb_request_form("Poke","invite_message",create_poke_path) do %>
      #    Send a poke to: <%= fb_friend_selector %> <br />
      #    <%= fb_request_form_submit %>
      #  <% end %>
      
      def fb_request_form(type ,message_param,url,&block)
        content = capture(&block)
        message = @_caught_content[message_param]
        concat(tag("fb:request-form", content,
                  {:action=>url,:method=>"post",:invite=>true,:type=>type,:content=>message}),
              block.binding)
      end
      
            
      # Provides a FBML fb_profile_pic tag with the provided uid
      # ==== Parameters
      # user<OrmObject>:: The user object
      # options<Hash>:: specify the users picture size
      #
      # === Options (options)
      #  :size<Symbol>:: The size of the profile picture :small, :normal and :square
      #
      # ==== Returns
      # String:: The fbml tag defaulting with thumb picture
      #
      # ==== Example
      #    <%=  fb_profile_pic(@user) %>
      def fb_profile_pic(user, options = {})
        validate_fb_profile_pic_size(options)
        options.merge!(:uid => cast_to_facebook_id(user))
        self_closing_tag("fb:profile-pic", options)
      end
      
      
      
      # Provides a FBML fb_photo tag with the a facebook photo
      # ==== Parameters
      # photo<Facebooker::Photo>:: The photo object Or Objec that respond to photo_id
      # options<Hash>:: specify the pic size and 
      #
      # === Options (options)
      #   <em> See: </em> http://wiki.developers.facebook.com/index.php/Fb:photo for complete list of options
      #
      # ==== Returns
      # String:: The fbml photo tag defaulting with thumb picture
      #
      # ==== Example
      #    <%=  fb_profile_pic(@user) %>
      def fb_photo(photo, options = {})
        # options.assert_valid_keys(FB_PHOTO_VALID_OPTION_KEYS) # TODO asserts
        options.merge!(:pid => cast_to_photo_id(photo))
        validate_fb_photo_size(options)
        validate_fb_photo_align_value(options)
        self_closing_tag("fb:photo", options)
      end
      
      def cast_to_photo_id(object)
        object.respond_to?(:photo_id) ? object.photo_id : object
      end
      
      protected
      def validate_fb_photo_align_value(options)
        if options.has_key?(:align) && !VALID_FB_PHOTO_ALIGN_VALUES.include?(options[:align].to_sym)
          raise(ArgumentError, "Unkown value for align: #{options[:align]}")
        end
      end
      
      def cast_to_facebook_id(object)
        Facebooker::User.cast_to_facebook_id(object)
      end
      
      def validate_fb_photo_size(options)
        if options.has_key?(:size) && !VALID_FB_PHOTO_SIZES.include?(options[:size].to_sym)
          raise(ArgumentError, "Unkown value for size: #{options[:size]}")
        end
      end
      
      def validate_fb_profile_pic_size(options)
        if options.has_key?(:size) && !VALID_FB_PROFILE_PIC_SIZES.include?(options[:size].to_sym)
          raise(ArgumentError, "Unkown value for size: #{options[:size]}")
        end
      end
      
    end # Helpers
  end # Merb
end # Facebooker