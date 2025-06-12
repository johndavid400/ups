module UpsShipping
  class Package
    attr_accessor :description, :packaging_type, :length, :width, :height, :weight, :dimension_unit, :weight_unit, :value

    def initialize(attrs = {})
      attrs.map{|k,v| send("#{k}=", v) if respond_to?("#{k}=") }

      @dimension_unit ||= 'IN'
      @weight_unit ||= 'LBS'
      @packaging_type ||= '02' # Customer Supplied Package
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
