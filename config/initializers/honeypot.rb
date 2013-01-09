module ActionView
  module Helpers
    module FormTagHelper
      def form_tag_with_honeypot(url_for_options = {}, options = {}, *parameters_for_url, &block)
        honeypot = options.delete(:honeypot)
        html = form_tag_without_honeypot(url_for_options, options, *parameters_for_url, &block)
        if honeypot
          captcha = "".respond_to?(:html_safe) ? honey_pot_captcha.html_safe : honey_pot_captcha
          if block_given?
            html.insert(html.index('</form>'), captcha)
          else
            html += captcha
          end
        end
        html
      end
      alias_method_chain :form_tag, :honeypot

    private

      def honey_pot_captcha
        html_ids = []
        honeypot_fields.collect do |f, l|
          html_ids << (html_id = "#{f}_hp_#{Time.now.to_i}")
          content_tag :div, :id => html_id do
            content_tag(:style, :type => 'text/css', :media => 'screen', :scoped => "scoped") do
              "#{html_ids.map { |i| "##{i}" }.join(', ')} { display:none; }"
            end +
            label_tag(f, l) +
            send([:text_field_tag, :text_area_tag][rand(2)], f)
          end
        end.join
      end
    end
  end
end

module HoneypotCaptcha
  module SpamProtection
    def honeypot_fields
      { :user_comments => 'Do not write here' }
    end

    def protect_from_spam
      head :ok if honeypot_fields.any? { |f,l| !params[f].blank? }
    end

    def self.included(base) # :nodoc:
      base.send :helper_method, :honeypot_fields
    end
  end
end

ActionController::Base.send(:include, HoneypotCaptcha::SpamProtection) if defined?(ActionController::Base)
