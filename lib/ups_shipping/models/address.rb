module UpsShipping
  class Address
    attr_accessor :name, :company_name, :attention_name, :address_line_1, :address_line_2,
                  :city, :state, :postal_code, :country_code, :phone, :tax_id

    def initialize(attributes = {})
      attributes.each do |key, value|
        send("#{key}=", value) if respond_to?("#{key}=")
      end
    end

    def validate!
      errors = []
      errors << "Address line 1 is required" if address_line_1.nil? || address_line_1.strip.empty?
      errors << "City is required" if city.nil? || city.strip.empty?
      errors << "State is required" if state.nil? || state.strip.empty?
      errors << "Postal code is required" if postal_code.nil? || postal_code.strip.empty?
      errors << "Country code is required" if country_code.nil? || country_code.strip.empty?

      raise ValidationError, errors.join(", ") unless errors.empty?
    end
  end
end
