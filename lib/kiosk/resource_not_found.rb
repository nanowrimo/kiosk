require 'active_resource'
require 'active_resource/exceptions'

class Kiosk::ResourceNotFound < ActiveResource::ResourceNotFound #:nodoc:
  def initialize(message)
    super(404, message)
  end

  def to_s
    @message
  end
end
