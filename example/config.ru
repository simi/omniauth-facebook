require 'bundler/setup'
require 'omniauth-facebook'
require './app.rb'

use Rack::Session::Cookie, secret: 'rqt2iy17g0vpkouu995r598671cihpae9mritav0yctevwqhprpr71oumzlv5c3z'

use OmniAuth::Builder do
  provider :facebook, ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_APP_SECRET']
end

run Sinatra::Application
