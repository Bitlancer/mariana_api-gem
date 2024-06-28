# frozen_string_literal: true

module MarianaApi
  module AdminApi
    module Resources; end
  end
end

Dir["#{File.dirname(__FILE__)}/resources/*.rb"].each { |file| require file }
