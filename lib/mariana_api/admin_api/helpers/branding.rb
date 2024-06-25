# frozen_string_literal: true

module MarianaApi
  module AdminApi
    module Helpers
      class Branding
        def initialize(api_client)
          @api_client = api_client
        end

        def logo_url(version = :auto)
          raise 'Unrecognized version' unless %i[auto dark light admin].include?(version)

          brand = @api_client.resources.tenant_brands.list(include: 'admin_login_logo').first

          light_logo = brand[:attributes][:logo_light]
          dark_logo = brand[:attributes][:logo_dark]
          admin_logo = brand[:relationships][:admin_login_logo][:data][:attributes][:image]

          return dark_logo if dark_logo && %i[auto dark].include?(version)
          return light_logo if light_logo && %i[auto light].include?(version)

          admin_logo if admin_logo && %i[auto admin].include?(version)
        end
      end
    end
  end
end
