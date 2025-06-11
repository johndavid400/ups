# lib/ups_shipping/shipping.rb
module UpsShipping
  class Shipping
    attr_reader :client

    def initialize(client)
      @client = client
    end

    def create_shipment(ship_request)
      endpoint = "/api/shipments/v1/ship?requestoption=nonvalidate"

      payload = build_ship_payload(ship_request)

      response = client.post(endpoint, body: payload)
      parse_ship_response(response)
    end

    private

    def build_ship_payload(ship_request)
      {
        ShipmentRequest: {
          Request: {
            RequestOption: "nonvalidate",
            TransactionReference: {
              CustomerContext: ship_request.reference || "Shipping Request"
            }
          },
          Shipment: {
            Description: ship_request.description || "Package",
            Shipper: {
              Name: ship_request.shipper.company_name,
              AttentionName: ship_request.shipper.attention_name,
              TaxIdentificationNumber: ship_request.shipper.tax_id,
              Phone: {
                Number: ship_request.shipper.phone
              },
              ShipperNumber: client.config.account_number,
              Address: address_hash(ship_request.shipper)
            },
            ShipTo: {
              Name: ship_request.ship_to.company_name || ship_request.ship_to.name,
              AttentionName: ship_request.ship_to.attention_name,
              Phone: {
                Number: ship_request.ship_to.phone
              },
              Address: address_hash(ship_request.ship_to)
            },
            ShipFrom: {
              Name: ship_request.ship_from.company_name || ship_request.ship_from.name,
              AttentionName: ship_request.ship_from.attention_name,
              Phone: {
                Number: ship_request.ship_from.phone
              },
              Address: address_hash(ship_request.ship_from)
            },
            PaymentInformation: {
              ShipmentCharge: {
                Type: "01",
                BillShipper: {
                  AccountNumber: client.config.account_number
                }
              }
            },
            Service: {
              Code: ship_request.service_code || "03",
              Description: "Service Code"
            },
            Package: ship_request.packages.map { |pkg| package_hash(pkg) }
          },
          LabelSpecification: {
            LabelImageFormat: {
              Code: ship_request.label_format || "GIF"
            },
            HTTPUserAgent: "UpsShipping Ruby Gem"
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
      {
        Description: package.description || "Package",
        Packaging: {
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
        }
      }
    end

    def parse_ship_response(response)
      if response['ShipmentResponse'] && response['ShipmentResponse']['ShipmentResults']
        results = response['ShipmentResponse']['ShipmentResults']

        {
          tracking_number: results['ShipmentIdentificationNumber'],
          label_url: results['PackageResults']['ShippingLabel']['GraphicImage'],
          total_cost: results['ShipmentCharges']['TotalCharges']['MonetaryValue'].to_f,
          currency: results['ShipmentCharges']['TotalCharges']['CurrencyCode']
        }
      else
        raise APIError, "Invalid shipment response: #{response}"
      end
    end
  end
end
