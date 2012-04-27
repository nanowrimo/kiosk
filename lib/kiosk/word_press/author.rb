module Kiosk
  module WordPress
    class Author < Resource
      schema do
        attribute 'name', :string
      end
    end
  end
end
