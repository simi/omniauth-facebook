# OmniAuth Facebook &nbsp;[![Build Status](http://travis-ci.org/mkdynamic/omniauth-facebook.png?branch=master)](http://travis-ci.org/mkdynamic/omniauth-facebook)

This gem contains the Facebook strategy for OmniAuth 1.0.

Supports the OAuth 2.0 server-side and client-side flows. Read the Facebook docs for more details: http://developers.facebook.com/docs/authentication

## Installing

Add to your `Gemfile`:

```ruby
gem 'omniauth-facebook'
```

Then `bundle install`.

## Usage

`OmniAuth::Strategies::Facebook` is simply a Rack middleware. Read the OmniAuth 1.0 docs for detailed instructions: https://github.com/intridea/omniauth.

Here's a quick example, adding the middleware to a Rails app in `config/initializers/omniauth.rb`:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, ENV['FACEBOOK_KEY'], ENV['FACEBOOK_SECRET']
end
```

See a full example of both server and client-side flows in the example Sinatra app in the `example/` folder above.

## Configuring

You can configure several options, which you pass in to the `provider` method via a `Hash`:

* `scope`: A comma-separated list of permissions you want to request from the user. See the Facebook docs for a full list of available permissions: http://developers.facebook.com/docs/reference/api/permissions. Default: `email,offline_access`
* `display`: The display context to show the authentication page. Options are: `page`, `popup`, `iframe`, `touch` and `wap`. Read the Facebook docs for more details: http://developers.facebook.com/docs/reference/dialogs#display. Default: `page`

For example, to request `email`, `offline_access` and `read_stream` permissions and display the authentication page in a popup window:
 
```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, ENV['FACEBOOK_KEY'], ENV['FACEBOOK_SECRET'], :scope => 'email,offline_access,read_stream', :display => 'popup'
end
```

*NB.* If you want to set the `display` format on a per-request basis, you can just pass it to the OmniAuth request phase URL, for example: `/auth/facebook?display=popup`.

## Authentication Hash

Here's an example *Authentication Hash* available in `request.env['omniauth.auth']`:

```ruby
{
  :provider => 'facebook',
  :uid => '1234567',
  :info => {
    :nickname => 'jbloggs',
    :email => 'joe@bloggs.com',
    :name => 'Joe Bloggs',
    :first_name => 'Joe',
    :last_name => 'Bloggs',
    :image => 'http://graph.facebook.com/1234567/picture?type=square',
    :urls => { :Facebook => 'http://www.facebook.com/jbloggs' },
    :location => 'Palo Alto, California'
  },
  :credentials => {
    :token => 'ABCDEF...', # OAuth 2.0 access_token, which you may wish to store
    :expires_at => 1321747205, # when the access token expires (if it expires)
    :expires => true # if you request `offline_access` this will be false
  },
  :extra => {
    :raw_info => {
      :id => '1234567',
      :name => 'Joe Bloggs',
      :first_name => 'Joe',
      :last_name => 'Bloggs',
      :link => 'http://www.facebook.com/jbloggs',
      :username => 'jbloggs',
      :location => { :id => '123456789', :name => 'Palo Alto, California' },
      :gender => 'male',
      :email => 'joe@bloggs.com',
      :timezone => -8,
      :locale => 'en_US',
      :verified => true,
      :updated_time => '2011-11-11T06:21:03+0000'
    }
  }
}
```

The precise information available may depend on the permissions which you request.

## Client-side Flow

The client-side flow supports parsing the authorization code from the signed request which Facebook puts into a cookie. This means you can to use the Facebook Javascript SDK as you would normally, and you just hit the callback endpoint (`/auth/facebook/callback` by default) once the user has authenticated in the `FB.login` success callback.

See the example Sinatra app under `example/` for more details.

## Supported Rubies

Actively tested with the following Ruby versions:

- MRI 1.9.3
- MRI 1.9.2
- MRI 1.8.7
- JRuby 1.6.5

*NB.* For JRuby, you'll need to install the `jruby-openssl` gem. There's no way to automatically specify this in a Rubygem gemspec, so you need to manually add it your project's own Gemfile:

```ruby
gem 'jruby-openssl', :platform => :jruby
```

## License

Copyright (c) 2011 by Mark Dodwell

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
