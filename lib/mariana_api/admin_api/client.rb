# frozen_string_literal: true

require_relative '../client'
require_relative 'resources'
require_relative 'helpers'

module MarianaApi
  module AdminApi
    class Client
      attr_reader :http_client

      def initialize(http_client)
        @http_client = http_client
      end

      def resources
        resources = OpenStruct.new
        Dir["#{File.dirname(__FILE__)}/resources/*.rb"].each do |file|
          resource_name = File.basename(file, '.rb')
          resource_class_name = resource_name.split('_').collect(&:capitalize).join
          resource_class = Object.const_get("MarianaApi::AdminApi::Resources::#{resource_class_name}")
          resources[resource_name] = resource_class.new(@http_client)
        end
        resources.freeze
        resources
      end

      def helpers
        helpers = OpenStruct.new
        Dir["#{File.dirname(__FILE__)}/helpers/*.rb"].each do |file|
          helper_name = File.basename(file, '.rb')
          helper_class_name = helper_name.split('_').collect(&:capitalize).join
          helper_class = Object.const_get("MarianaApi::AdminApi::Helpers::#{helper_class_name}")
          helpers[helper_name] = helper_class.new(self)
        end
        helpers.freeze
        helpers
      end
    end
  end
end
