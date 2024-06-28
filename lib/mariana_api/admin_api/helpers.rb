# frozen_string_literal: true

module MarianaApi
  module AdminApi
    module Helpers; end
  end
end

Dir["#{File.dirname(__FILE__)}/helpers/*.rb"].each { |file| require file }
