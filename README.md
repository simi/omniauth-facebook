**NOTE: If you're running < 1.5.1, please upgrade to address 2 security vulnerabilities.
More details [here](https://github.com/mkdynamic/omniauth-facebook/wiki/CSRF-vulnerability:-CVE-2013-4562) and [here](https://github.com/mkdynamic/omniauth-facebook/wiki/Access-token-vulnerability:-CVE-2013-4593).**

---

# OmniAuth Facebook &nbsp;[![Build Status](https://secure.travis-ci.org/mkdynamic/omniauth-facebook.png?branch=master)](https://travis-ci.org/mkdynamic/omniauth-facebook)

Facebook OAuth2 Strategy for OmniAuth.

Supports the OAuth 2.0 server-side and client-side flows. Read the Facebook docs for more details: http://developers.facebook.com/docs/authentication

## Installing

Add to your `Gemfile`:

```ruby
gem 'omniauth-facebook'
```

Then `bundle install`.

## Usage

`OmniAuth::Strategies::Facebook` is simply a Rack middleware. Read the OmniAuth docs for detailed instructions: https://github.com/intridea/omniauth.

Here's a quick example, adding the middleware to a Rails app in `config/initializers/omniauth.rb`:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, ENV['FACEBOOK_KEY'], ENV['FACEBOOK_SECRET']
end
```

[See the example Sinatra app for full examples](https://github.com/mkdynamic/omniauth-facebook/blob/master/example/config.ru) of both the server and client-side flows (including using the Facebook Javascript SDK).

## Configuring

You can configure several options, which you pass in to the `provider` method via a `Hash`:

* `scope`: A comma-separated list of permissions you want to request from the user. See the Facebook docs for a full list of available permissions: http://developers.facebook.com/docs/reference/api/permissions. Default: `email`
* `display`: The display context to show the authentication page. Options are: `page`, `popup` and `touch`. Read the Facebook docs for more details: https://developers.facebook.com/docs/reference/dialogs/oauth/. Default: `page`
* `auth_type`: Optionally specifies the requested authentication features as a comma-separated list, as per https://developers.facebook.com/docs/authentication/reauthentication/.
Valid values are `https` (checks for the presence of the secure cookie and asks for re-authentication if it is not present), and `reauthenticate` (asks the user to re-authenticate unconditionally). Default is `nil`.
* `secure_image_url`: Set to `true` to use https for the avatar image url returned in the auth hash. Default is `false`.
* `image_size`: Set the size for the returned image url in the auth hash. Valid options include `square` (50x50), `small` (50 pixels wide, variable height), `normal` (100 pixels wide, variable height), or `large` (about 200 pixels wide, variable height). Additionally, you can request a picture of a specific size by setting this option to a hash with `:width` and `:height` as keys. This will return an available profile picture closest to the requested size and requested aspect ratio. If only `:width` or `:height` is specified, we will return a picture whose width or height is closest to the requested size, respectively.
* `info_fields`: Specify exactly which fields should be returned when getting the user's info. Value should be a comma-separated string as per https://developers.facebook.com/docs/reference/api/user/ (only /me endpoint).
* `locale`: Specify locale which should be used when getting the user's info. Value should be locale string as per https://developers.facebook.com/docs/reference/api/locale/.

For example, to request `email`, `user_birthday` and `read_stream` permissions and display the authentication page in a popup window:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, ENV['FACEBOOK_KEY'], ENV['FACEBOOK_SECRET'],
           :scope => 'email,user_birthday,read_stream', :display => 'popup'
end
```

### Per-Request Options

If you want to set the `display` format, `auth_type`, or `scope` on a per-request basis, you can just pass it to the OmniAuth request phase URL, for example: `/auth/facebook?display=popup` or `/auth/facebook?scope=email`.

### Custom Callback URL/Path

You can set a custom `callback_url` or `callback_path` option to override the default value. See [OmniAuth::Strategy#callback_url](https://github.com/intridea/omniauth/blob/master/lib/omniauth/strategy.rb#L411) for more details on the default.

## Auth Hash

Here's an example *Auth Hash* available in `request.env['omniauth.auth']`:

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
    :location => 'Palo Alto, California',
    :verified => true
  },
  :credentials => {
    :token => 'ABCDEF...', # OAuth 2.0 access_token, which you may wish to store
    :expires_at => 1321747205, # when the access token expires (it always will)
    :expires => true # this will always be true
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

You can use the Facebook Javascript SDK with `FB.login`, and just hit the callback endpoint (`/auth/facebook/callback` by default) once the user has authenticated in the success callback.

Note that you must enable cookies in the `FB.init` config for this process to work.

See the example Sinatra app under `example/` and read the [Facebook docs on Client-Side Authentication](https://developers.facebook.com/docs/authentication/client-side/) for more details.

### How it Works

The client-side flow is supported by parsing the authorization code from the signed request which Facebook places in a cookie.

When you call `/auth/facebook/callback` in the success callback of `FB.login` that will pass the cookie back to the server. omniauth-facebook will see this cookie and:

1. parse it,
2. extract the authorization code contained in it
3. and hit Facebook and obtain an access token which will get placed in the `request.env['omniauth.auth']['credentials']` hash.

Note that this access token will be the same token obtained and available in the client through the hash [as detailed in the Facebook docs](https://developers.facebook.com/docs/authentication/client-side/).

## Canvas Apps

Canvas apps will send a signed request with the initial POST, therefore you *can* (if it makes sense for your app) pass this to the authorize endpoint (`/auth/facebook` by default) in the querystring.

There are then 2 scenarios for what happens next:

1. A user has already granted access to your app, this will contain an access token. In this case, omniauth-facebook will skip asking the user for authentication and immediately redirect to the callback endpoint (`/auth/facebook/callback` by default) with the access token present in the `request.env['omniauth.auth']['credentials']` hash.

2. A user has not granted access to your app, and the signed request *will not* contain an access token. In this case omniauth-facebook will simply follow the standard auth flow.

Take a look at [the example Sinatra app for one option of how you can integrate with a canvas page](https://github.com/mkdynamic/omniauth-facebook/blob/master/example/config.ru).

Bear in mind you have several [options](https://developers.facebook.com/docs/opengraph/authentication). Read [the Facebook docs on canvas page  authentication](https://developers.facebook.com/docs/authentication/canvas/) for more info.

## Token Expiry

Since Facebook deprecated the `offline_access` permission, this has become more complex. The expiration time of the access token you obtain will depend on which flow you are using. See below for more details.

### Client-Side Flow

If you use the client-side flow, Facebook will give you back a short lived access token (~ 2 hours).

You can exchange this short lived access token for a longer lived version. Read the [Facebook docs about the offline_access  deprecation](https://developers.facebook.com/roadmap/offline-access-removal/) for more information.

### Server-Side Flow

If you use the server-side flow, Facebook will give you back a longer lived access token (~ 60 days).

If you're having issue getting a long lived token with the server-side flow, make sure to enable the 'deprecate offline_access setting' in you Facebook app config. Read the [Facebook docs about the offline_access  deprecation](https://developers.facebook.com/roadmap/offline-access-removal/) for more information.

## Supported Rubies

Actively tested with the following Ruby versions:

- MRI 2.0.0
- MRI 1.9.3
- MRI 1.9.2
- MRI 1.8.7
- JRuby 1.7.4

*NB.* For JRuby < 1.7, you'll need to install the `jruby-openssl` gem. There's no way to automatically specify this in a Rubygem gemspec, so you need to manually add it your project's own Gemfile:

```ruby
gem 'jruby-openssl', :platform => :jruby
```

## License

Copyright (c) 2012 by Mark Dodwell

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
