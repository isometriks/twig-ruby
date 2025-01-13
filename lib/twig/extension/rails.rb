module Twig
  module Extension
    class Rails < Extension::Base
      def filters
        {}
      end

      def helper_methods
        %w[
          distance_of_time_in_words
          time_ago_in_words

          number_to_currency
          number_to_human
          number_to_human_size
          number_to_percentage
          number_to_phone
          number_with_delimiter
          number_with_precision

          excerpt
          pluralize
          truncate
          word_wrap

          button_to
          current_page?
          link_to
          mail_to
          url_for

          raw
          sanitize
          sanitize_css
          strip_links
          strip_tags

          audio_tag
          auto_discovery_link_tag
          favicon_link_tag
          image_tag
          javascript_include_tag
          picture_tag
          preload_link_tag
          stylesheet_link_tag
          video_tag

          escape_javascript
          javascript_tag

          benchmark
          cache
          debug

          tag
          token_list

          form_for
          form_with

          date_test
        ]
      end
    end
  end
end
