require 'i18n'

module Kiosk
  # Provides an +ActionController+ filter that scopes all content resource
  # calls to only fetch content for the default locale and localize it all to
  # the current request locale.
  #
  module Localizer
    def self.around(controller)
      Resource.with_locale(Kiosk.origin.default_locale || I18n.default_locale) do
        Resource.localized_to(I18n.locale) do
          yield
        end
      end
    end
  end
end
