require 'active_support/concern'

module Kiosk
  # Provides integration between I18n and WordPress for automatic retrieval of
  # content translated to the language of the user session. This module
  # depends on the installation of the WPML-JSON-API WordPress plugin.
  #
  module Localizable::Resource
    extend ActiveSupport::Concern

    module ClassMethods
      attr_accessor :locale_scope_stack

      # Executes the given block within a scope that limits found content
      # resources to the given locale.
      #
      def with_locale(locale, &blk)
        with_parameters(:language => locale, &blk)
      end

      # Executes the given block within a scope that translates found content
      # resources to the given locale. See +Resource.with_params+ for details
      # on scope execution and inheritance.
      #
      def localized_to(locale, &blk)
        with_parameters(:to_language => locale, &blk)
      end
    end
  end
end
