module HockeyApp
  class AppUser
    extend  ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations
    include ActiveModelCompliance

    ATTRIBUTES = %i[id role invited_by invited_at created_at email full_name tags].freeze

    attr_accessor *ATTRIBUTES
    attr_reader :app

    def self.from_hash(h, app, client)
      res = new app, client
      ATTRIBUTES.each do |attribute|
        res.send("#{attribute}=", h[attribute.to_s]) unless h[attribute.to_s].nil?
      end
      res
    end

    def initialize(app, client)
      @app = app
      @client = client
    end

    private

    attr_accessor :client
  end
end
