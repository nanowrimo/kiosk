module Kiosk
  module WordPress
    class Attachment < Resource
      claims_path_content(:selector => 'a, img', :pattern => 'files/\d{4}/\d{2}/:slug')
    end
  end
end
