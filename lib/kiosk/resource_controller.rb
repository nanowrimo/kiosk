module Kiosk
  module ResourceController
    def show
      self.resource = resource_model.find_by_slug(params[:id] || params[:slug])
    end

    # Can be used as an endpoint for the CMS to expire the cache.
    #
    def update
      model = resource_model

      if model.respond_to?(:expire)
        resource = model.new(params)

        # Expire for all target locales if the resource is localizable
        if model.respond_to?(:localized_to)
          I18n.available_locales.each do |locale|
            model.localized_to(locale) do
              resource.expire
            end
          end
        else
          resource.expire
        end
      end

      render :nothing => true
    end

    private

    # Resolves the model from the controller name.
    #
    def resource_model
      names = self.class.name.split('::')
      controller = names.pop
      (names.join('::') + '::' + controller.sub('Controller', '').singularize).constantize
    end

    def resource_name
      resource_model.name.split('::').last.underscore
    end

    def resource=(resource)
      instance_variable_set("@#{resource_name}".to_sym, resource)
      @resource = resource
    end
  end
end
