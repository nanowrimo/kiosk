def mock_class(superklass = nil)
  Class.new(superklass) do
    def self.name
      @name ||= 'X' + SecureRandom.hex[0..8]
    end
  end
end
