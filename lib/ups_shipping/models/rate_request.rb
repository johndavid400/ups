# lib/ups_shipping/models/rate_request.rb
module UpsShipping
  class RateRequest
    attr_accessor :shipper, :ship_to, :ship_from, :packages, :service_code, :reference

    def initialize(attributes = {})
      @packages = []

      attributes.each do |key, value|
        send("#{key}=", value) if respond_to?("#{key}=")
      end
    end

    def add_package(package)
      @packages << package
    end

    def validate!
      errors = []
      errors << "Shipper is required" if shipper.nil?
      errors << "Ship to address is required" if ship_to.nil?
      errors << "Ship from address is required" if ship_from.nil?
      errors << "At least one package is required" if packages.empty?

      begin
        shipper&.validate!
        ship_to&.validate!
        ship_from&.validate!
        packages.each(&:validate!)
      rescue ValidationError => e
        errors << e.message
      end

      raise ValidationError, errors.join(", ") unless errors.empty?
    end
  end
end
