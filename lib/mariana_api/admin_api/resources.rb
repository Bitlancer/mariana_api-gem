module MarianaApi::AdminApi::Resources; end

Dir[File.dirname(__FILE__) + '/resources/*.rb'].each { |file| require file }
