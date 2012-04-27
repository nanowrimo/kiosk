module Kiosk::Indexer::Adapter
  class Base
    def extend_model(model)
      model.class_exec(self.class.const_get(:Resource)) { |mixin| include mixin }
    end

    def index(name)
    end
  end
end
