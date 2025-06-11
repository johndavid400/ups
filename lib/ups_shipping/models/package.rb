# lib/ups_shipping/models/package.rb
module UpsShipping
  class Package
    attr_accessor :description, :packaging_type, :length, :width, :height,
                  :weight, :dimension_unit, :weight_unit

    def initialize(attributes = {})
      @dimension_unit = "IN"
      @weight_unit = "LBS"
      @packaging_type = "02" # Customer Supplied Package

      attributes.each do |key, value|
        send("#{key}=", value) if respond_to?("#{key}=")
      end
    end

    def validate!
      errors = []
      errors << "Length is required" if length.nil? || length <= 0
      errors << "Width is required" if width.nil? || width <= 0
      errors << "Height is required" if height.nil? || height <= 0
      errors << "Weight is required" if weight.nil? || weight <= 0

      raise ValidationError, errors.join(", ") unless errors.empty?
    end
  end
end
