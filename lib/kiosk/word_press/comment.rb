module Kiosk
  module WordPress
    class Comment < Resource
      schema do
        attribute 'name', :string
        attribute 'url', :string
        attribute 'date', :string
        attribute 'content', :string
        attribute 'parent', :integer
      end
    end
  end
end
