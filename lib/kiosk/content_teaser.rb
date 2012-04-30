module Kiosk
  module ContentTeaser
    # Returns a teaser of the content. The content is parsed as HTML and
    # tidy'd up after the truncation is performed so the given +horizon+ may
    # not be strictly adhered to.
    #
    def teaser(horizon)
      Nokogiri::HTML.fragment(content.truncate([horizon - 18, 36].max)).to_html if content
    end
  end
end
