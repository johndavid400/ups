module Ups
  class Rating
    attr_reader :client, :account_number

    def initialize(client, account_number: nil)
      @client = client
      @account_number = account_number || client.config.account_number
    end

    def get_rates(rate_request)
      endpoint = "/api/rating/v2409/Shop"
      payload = build_rate_payload(rate_request)
      response = client.post(endpoint, body: payload)
      parse_rate_response(response)
    end

    private

    def build_rate_payload(rate_request)
      {
        RateRequest: {
          Request: {
            RequestOption: "Rate",
            TransactionReference: {
              CustomerContext: rate_request.reference || "Rating Request"
            }
          },
          Shipment: {
            ShipmentDate: Date.today.to_s,
            Shipper: {
              Name: rate_request.shipper.company_name,
              ShipperNumber: client.config.account_number,
              Address: address_hash(rate_request.shipper)
            },
            ShipTo: {
              Name: rate_request.ship_to.company_name || rate_request.ship_to.name,
              Address: address_hash(rate_request.ship_to)
            },
            ShipFrom: {
              Name: rate_request.ship_from.company_name || rate_request.ship_from.name,
              Address: address_hash(rate_request.ship_from)
            },
            PaymentInformation: {
              ShipmentCharge: {
                Type: "01",
                BillShipper: {
                  AccountNumber: account_number
                }
              }
            },
            Package: rate_request.packages.map { |pkg| package_hash(pkg) },
            Service: {
              Code: rate_request.service_code || "03"
            }
          }
        }
      }
    end

    def address_hash(address)
      {
        AddressLine: [address.address_line_1, address.address_line_2].compact,
        City: address.city,
        StateProvinceCode: address.state,
        PostalCode: address.postal_code,
        CountryCode: address.country_code
      }
    end

    def package_hash(package)
      base = {
        PackagingType: {
          Code: package.packaging_type || "02"
        },
        Dimensions: {
          UnitOfMeasurement: {
            Code: package.dimension_unit || "IN"
          },
          Length: package.length.to_s,
          Width: package.width.to_s,
          Height: package.height.to_s
        },
        PackageWeight: {
          UnitOfMeasurement: {
            Code: package.weight_unit || "LBS"
          },
          Weight: package.weight.to_s
        },
        PackageServiceOptions: {
          DeclaredValue: {
            CurrencyCode: "USD",
            MonetaryValue: package.insurance
          }
        }
      }
      base.deep_merge!(signature_required(package.delivery_confirmation)) if [2,3].include?(package&.delivery_confirmation.to_i)
      base
    end

    def signature_required(type = '3')
      {
        PackageServiceOptions: {
          DeliveryConfirmation: {
            DCISType: type.to_s
          }
        }
      }
    end

    def parse_rate_response(response)
      rates = []

      if response['RateResponse'] && response['RateResponse']['RatedShipment']
        rated_shipments = response['RateResponse']['RatedShipment']
        rated_shipments = [rated_shipments] unless rated_shipments.is_a?(Array)

        rated_shipments.each do |shipment|
          rates << {
            service_code: shipment['Service']['Code'],
            service_name: get_service_name(shipment['Service']['Code']),
            total: shipment['TotalCharges']['MonetaryValue'].to_f,
            currency: shipment['TotalCharges']['CurrencyCode'],
            transit_time: shipment['GuaranteedDelivery'] ? shipment['GuaranteedDelivery']['BusinessDaysInTransit'] : nil
          }
        end
      end

      rates
    end

    def get_service_name(code)
      service_names[code] || "Unknown Service (#{code})"
    end

    def service_names
      @service_names ||= {
        '01' => 'UPS Next Day Air',
        '02' => 'UPS 2nd Day Air',
        '03' => 'UPS Ground',
        '07' => 'UPS Worldwide Express',
        '08' => 'UPS Worldwide Expedited',
        '11' => 'UPS Standard',
        '12' => 'UPS 3 Day Select',
        '13' => 'UPS Next Day Air Saver',
        '14' => 'UPS Next Day Air Early AM',
        '54' => 'UPS Worldwide Express Plus',
        '59' => 'UPS 2nd Day Air AM',
        '65' => 'UPS Saver'
      }
    end

  end
end
