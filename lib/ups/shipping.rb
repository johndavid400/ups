module Ups
  class Shipping
    attr_reader :client, :account_number, :negotiated_rates

    def initialize(client, account_number: nil)
      @client = client
      @account_number = account_number || client.config.account_number
      @negotiated_rates = client.config&.negotiated_rates || false
    end

    def create_shipment(ship_request)
      endpoint = "/api/shipments/v2409/ship"
      payload = build_ship_payload(ship_request)
      payload.deep_merge!(negotiated_rates_json) if negotiated_rates
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
            ShipmentDate: Date.today.to_s,
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
                  AccountNumber: account_number
                }
              }
            },
            Service: {
              Code: ship_request.service_code || "02",
              Description: "Service Code"
            },
            Package: ship_request.packages.map { |pkg| package_hash(pkg) }
          },
          LabelSpecification: {
            LabelImageFormat: {
              Code: ship_request.label_format || "GIF"
            },
            HTTPUserAgent: "UPS Rate Fetch"
          }
        }
      }
    end

    def negotiated_rates_json
      {
        ShipmentRequest: {
          Shipment: {
            ShipmentRatingOptions: {
              NegotiatedRatesIndicator: "X"
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
        },
        PackageServiceOptions: {
          DeclaredValue: {
            CurrencyCode: "USD",
            MonetaryValue: package.insurance
          }
        },
        InsuredValue: {
          CurrencyCode: "USD",
          MonetaryValue: package.insurance
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

    def parse_ship_response(response)
      if response['ShipmentResponse'] && response['ShipmentResponse']['ShipmentResults']
        results = response['ShipmentResponse']['ShipmentResults']
        {
          tracking_number: results['ShipmentIdentificationNumber'],
          label: results['PackageResults'][0]['ShippingLabel']['GraphicImage'],
          extension: results['PackageResults'][0]['ShippingLabel']['ImageFormat']['Code'],
          total: get_rate_value(results['ShipmentCharges']),
          currency: results['ShipmentCharges']['TotalCharges']['CurrencyCode'],
          data: response.as_json(except: ["GraphicImage", "HTMLImage"]),
          alerts: response['ShipmentResponse']['Response']['Alert']&.map{|s| s['Description'] }
        }
      else
        raise APIError, "Invalid shipment response: #{response}"
      end
    end

    def get_rate_value(data)
      return data.dig('NegotiatedRateCharges', 'TotalCharge', 'MonetaryValue').to_f if negotiated_rates

      data.dig('TotalCharges', 'MonetaryValue').to_f
    end

  end
end
