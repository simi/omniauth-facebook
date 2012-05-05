require 'bundler/setup'
require 'sinatra/base'
require 'omniauth-facebook'

SCOPE = 'email,read_stream'

class App < Sinatra::Base
  # turn off sinatra default X-Frame-Options for FB canvas
  set :protection, :except => :frame_options

  # server-side flow
  get '/' do
    # NOTE: you would just hit this endpoint directly from the browser
    #       in a real app. the redirect is just here to setup the root
    #       path in this example sinatra app.
    redirect '/auth/facebook'
  end

  # client-side flow
  get '/client-side' do
    content_type 'text/html'
    # NOTE: when you enable cookie below in the FB.init call
    #       the GET request in the FB.login callback will send
    #       a signed request in a cookie back the OmniAuth callback
    #       which will parse out the authorization code and obtain
    #       the access_token. This will be the exact same access_token
    #       returned to the client in response.authResponse.accessToken.
    <<-END
      <html>
      <head>
        <title>Client-side Flow Example</title>
        <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.0/jquery.min.js" type="text/javascript"></script>
      </head>
      <body>
        <div id="fb-root"></div>

        <script type="text/javascript">
          window.fbAsyncInit = function() {
            FB.init({
              appId  : '#{ENV['APP_ID']}',
              status : true, // check login status
              cookie : true, // enable cookies to allow the server to access the session
              xfbml  : true  // parse XFBML
            });
          };

          (function(d) {
            var js, id = 'facebook-jssdk'; if (d.getElementById(id)) {return;}
            js = d.createElement('script'); js.id = id; js.async = true;
            js.src = "//connect.facebook.net/en_US/all.js";
            d.getElementsByTagName('head')[0].appendChild(js);
          }(document));

          $(function() {
            $('a').click(function(e) {
              e.preventDefault();

              FB.login(function(response) {
                if (response.authResponse) {
                  $('#connect').html('Connected! Hitting OmniAuth callback (GET /auth/facebook/callback)...');

                  // since we have cookies enabled, this request will allow omniauth to parse
                  // out the auth code from the signed request in the fbsr_XXX cookie
                  $.getJSON('/auth/facebook/callback', function(json) {
                    $('#connect').html('Connected! Callback complete.');
                    $('#results').html(JSON.stringify(json));
                  });
                }
              }, { scope: '#{SCOPE}' });
            });
          });
        </script>

        <p id="connect">
          <a href="#">Connect to FB</a>
        </p>

        <p id="results" />
      </body>
      </html>
    END
  end

  # auth via FB canvas and signed request param
  post '/canvas/' do
    # we just redirect to /auth/facebook here which will parse the
    # signed_request FB sends us, asking for auth if the user has
    # not already granted access, or simply moving straight to the
    # callback where they have already granted access.
    #
    # we pass the state parameter which we can detect in our callback
    # to do custom rendering/redirection for the canvas app page
    redirect "/auth/facebook?signed_request=#{request.params['signed_request']}&state=canvas"
  end

  get '/auth/:provider/callback' do
    # we can do something special here is +state+ param is canvas
    # (see notes above in /canvas/ method for more details)
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
  provider :facebook, ENV['APP_ID'], ENV['APP_SECRET'], :scope => SCOPE
end

run App.new
