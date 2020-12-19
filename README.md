# Mariana API Client

A Ruby client for interacting with the Mariana Tek API.

## Usage

### CLI

Setup:


```shell
cat <<EOF >.partner_credentials
{
  api_key: "1E0...",
  client_id: "ha0...",
  redirect_uri: "http://app.example.com/oauth/callback"
}
EOF

./bin/console
[1] pry(main)> system("open \"#{CLIENT.get_authorize_url}\"")
[2] pry(main)> token = CLIENT.get_user_token(auth_code: '...') # code from URL
[3] pry(main)> File.write('.user_token', token.to_h.to_json)
```

Usage:

```shell
export OAUTH_DEBUG=true  # To debug HTTP calls
./bin/console
[1] pry(main)> api = CLIENT.admin_api_client
[2] pry(main)> api.resources.users.read
```

### Ruby

```ruby
partner_creds = {
  api_key: "1E0...",
  client_id: "ha0...",
  redirect_uri: "https://app.example.com/oauth/callback"
}

subdomain = 'example.sandbox'

user_token = {
  access_token: "a12...",
  created_at: 1600390842
  expires_in: 7200,
  refresh_token: "ce2...",
  token_type: "Bearer"
}

client = MarianaApi::AdminApi::Client.new(partner_creds, subdomain, user_token)
client.http_client.on_token_refresh = Proc.new do |token|
  # Save new token to database
end

me = client.resources.users.read
```
