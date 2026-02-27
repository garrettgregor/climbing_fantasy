class ApplicationQuery
  class << self
    def call(params = {})
      new(params).call
    end
  end
end
