require 'bundler/setup'
require 'sinatra/base'
require 'omniauth-facebook'

class App < Sinatra::Base
  get '/' do
    redirect '/auth/facebook'
  end

  get '/auth/:provider/callback' do
    content_type 'application/json'
    MultiJson.encode(request.env)
  end
  
  get '/auth/failure' do
    content_type 'application/json'
    MultiJson.encode(request.env)
  end
end

use Rack::Session::Cookie

use OmniAuth::Builder do
  provider :facebook, ENV['APP_ID'], ENV['APP_SECRET'], :scope => 'email,read_stream', :display => 'popup'
end

run App.new
