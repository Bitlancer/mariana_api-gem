# frozen_string_literal: true

require 'mariana_api'

describe 'Client' do
  before(:all) do
    subdomain = 'test'
    credentials = {
      api_key: '$API_KEY$',
      client_id: '$CLIENT_ID$',
      redirect_uri: 'http://localhost:3000'
    }
    @client = MarianaApi::Client.new(credentials, subdomain)
    @client.logger = Logger.new('/dev/null')
  end

  describe '#get' do
    it 'passes authentication' do
      stub_request(:get, 'https://test.marianatek.com/api/users?page_size=100')
        .with(headers: { Authorization: 'Bearer $API_KEY$' })
        .to_return(body: '{}')
      @client.get('/api/users', auth_type: :api_key)
    end

    it 'retries failed requests' do
      stub = stub_request(:get, 'https://test.marianatek.com/api/locations?page_size=100')
             .to_return(status: 503)
      expect { @client.get('/api/locations', retries: 2) }.to raise_error(Net::HTTPRetriableError)
      expect(stub).to have_been_requested.times(3)
    end

    it 'retrieves a paginated dataset with includes' do
      stub_request(:get, 'https://test.marianatek.com/api/locations?page_size=10&include=region')
        .to_return(body: File.read('spec/fixtures/locations-page-1.json'))

      stub_request(:get, 'https://test.marianatek.com/api/locations?page_size=10&page=2&include=region')
        .to_return(body: File.read('spec/fixtures/locations-page-2.json'))

      locations = @client.get('/api/locations', params: { page_size: 10, include: 'region' })
      expect(locations.size).to eql(16)
      expect(locations.map { |l| l[:attributes][:name] }).to include('Point Loma')
      expect(locations.first[:relationships][:region][:data][:attributes][:name]).to eql('New York')
    end
  end
end
