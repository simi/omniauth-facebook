require 'spec_helper'
require 'omniauth-facebook'

describe OmniAuth::Strategies::Facebook do
  before :each do
    @request = double('Request')
    @request.stub(:params) { {} }
  end
  
  subject do
    OmniAuth::Strategies::Facebook.new(nil, @options || {}).tap do |strategy|
      strategy.stub(:request) { @request }
    end
  end

  it_should_behave_like 'an oauth2 strategy'

  describe '#client' do
    it 'has correct Facebook site' do
      subject.client.site.should eq('https://graph.facebook.com')
    end

    it 'has correct authorize url' do
      subject.client.options[:authorize_url].should eq('/oauth/authorize')
    end

    it 'has correct token url' do
      subject.client.options[:token_url].should eq('/oauth/access_token')
    end
  end

  describe '#authorize_params' do
    it 'includes default scope for email and offline access' do
      subject.authorize_params.should be_a(Hash)
      subject.authorize_params[:scope].should eq('email,offline_access')
    end
  
    it 'includes display parameter from request when present' do
      @request.stub(:params) { { 'display' => 'touch' } }
      subject.authorize_params.should be_a(Hash)
      subject.authorize_params[:display].should eq('touch')
    end
  end

  describe '#token_params' do
    it 'has correct parse strategy' do
      subject.token_params[:parse].should eq(:query)
    end
  end

  describe '#access_token_options' do
    it 'has correct param name by default' do
      subject.access_token_options[:param_name].should eq('access_token')
    end

    it 'has correct header format by default' do
      subject.access_token_options[:header_format].should eq('OAuth %s')
    end
  end
  
  describe '#uid' do
    before :each do
      subject.stub(:raw_info) { { 'id' => '123' } }
    end
    
    it 'returns the id from raw_info' do
      subject.uid.should eq('123')
    end
  end
  
  describe '#info' do
    before :each do
      @raw_info ||= { 'name' => 'Fred Smith' }
      subject.stub(:raw_info) { @raw_info }
    end
    
    context 'when optional data is not present in raw info' do
      it 'has no email key' do
        subject.info.should_not have_key('email')
      end

      it 'has no nickname key' do
        subject.info.should_not have_key('nickname')
      end
    
      it 'has no first name key' do
        subject.info.should_not have_key('first_name')
      end
    
      it 'has no last name key' do
        subject.info.should_not have_key('last_name')
      end
    
      it 'has no location key' do
        subject.info.should_not have_key('location')
      end
    
      it 'has no description key' do
        subject.info.should_not have_key('description')
      end
    
      it 'has no urls' do
        subject.info.should_not have_key('urls')
      end
    end
    
    context 'when data is present in raw info' do
      it 'returns the name' do
        subject.info['name'].should eq('Fred Smith')
      end
    
      it 'returns the email' do
        @raw_info['email'] = 'fred@smith.com'
        subject.info['email'].should eq('fred@smith.com')
      end

      it 'returns the username as nickname' do
        @raw_info['username'] = 'fredsmith'
        subject.info['nickname'].should eq('fredsmith')
      end
    
      it 'returns the first name' do
        @raw_info['first_name'] = 'Fred'
        subject.info['first_name'].should eq('Fred')
      end
    
      it 'returns the last name' do
        @raw_info['last_name'] = 'Smith'
        subject.info['last_name'].should eq('Smith')
      end
    
      it 'returns the location name as location' do
        @raw_info['location'] = { 'id' => '104022926303756', 'name' => 'Palo Alto, California' }
        subject.info['location'].should eq('Palo Alto, California')
      end
    
      it 'returns bio as description' do
        @raw_info['bio'] = 'I am great'
        subject.info['description'].should eq('I am great')
      end
    
      it 'returns the square format facebook avatar url' do
        @raw_info['id'] = '321'
        subject.info['image'].should eq('http://graph.facebook.com/321/picture?type=square')
      end
    
      it 'returns the Facebook link as the Facebook url' do
        @raw_info['link'] = 'http://www.facebook.com/fredsmith'
        subject.info['urls'].should be_a(Hash)
        subject.info['urls']['Facebook'].should eq('http://www.facebook.com/fredsmith')
      end
    
      it 'returns website url' do
        @raw_info['website'] = 'https://my-wonderful-site.com'
        subject.info['urls'].should be_a(Hash)
        subject.info['urls']['Website'].should eq('https://my-wonderful-site.com')
      end
    
      it 'return both Facebook link and website urls' do
        @raw_info['link'] = 'http://www.facebook.com/fredsmith'
        @raw_info['website'] = 'https://my-wonderful-site.com'
        subject.info['urls'].should be_a(Hash)
        subject.info['urls']['Facebook'].should eq('http://www.facebook.com/fredsmith')
        subject.info['urls']['Website'].should eq('https://my-wonderful-site.com')
      end
    end
  end
  
  describe '#raw_info' do
    before :each do
      @access_token = double('OAuth2::AccessToken')
      subject.stub(:access_token) { @access_token }
    end
    
    it 'performs a GET to https://graph.facebook.com/me' do
      @access_token.stub(:get) { double('OAuth2::Response').as_null_object }
      @access_token.should_receive(:get).with('/me')
      subject.raw_info
    end
    
    it 'returns a Hash' do
      @access_token.stub(:get).with('/me') do
        raw_response = double('Faraday::Response')
        raw_response.stub(:body) { '{ "ohai": "thar" }' }
        raw_response.stub(:status) { 200 }
        raw_response.stub(:headers) { { 'Content-Type' => 'application/json' } }
        OAuth2::Response.new(raw_response)
      end
      subject.raw_info.should be_a(Hash)
      subject.raw_info['ohai'].should eq('thar')
    end
  end

  describe '#credentials' do
    before :each do
      @access_token = double('OAuth2::AccessToken')
      @access_token.stub(:token)
      @access_token.stub(:expires?)
      @access_token.stub(:expires_at)
      @access_token.stub(:refresh_token)
      subject.stub(:access_token) { @access_token }
    end
    
    it 'returns a Hash' do
      subject.credentials.should be_a(Hash)
    end
    
    it 'returns the token' do
      @access_token.stub(:token) { '123' }
      subject.credentials['token'].should eq('123')
    end
    
    it 'returns the expiry status' do
      @access_token.stub(:expires?) { true }
      subject.credentials['expires'].should eq(true)
      
      @access_token.stub(:expires?) { false }
      subject.credentials['expires'].should eq(false)
    end
    
    it 'returns the refresh token and expiry time when expiring' do
      ten_mins_from_now = (Time.now + 600).to_i
      @access_token.stub(:expires?) { true }
      @access_token.stub(:refresh_token) { '321' }
      @access_token.stub(:expires_at) { ten_mins_from_now }
      subject.credentials['refresh_token'].should eq('321')
      subject.credentials['expires_at'].should eq(ten_mins_from_now)
    end
    
    it 'does not return the refresh token when it is nil and expiring' do
      @access_token.stub(:expires?) { true }
      @access_token.stub(:refresh_token) { nil }
      subject.credentials['refresh_token'].should be_nil
      subject.credentials.should_not have_key('refresh_token')
    end
    
    it 'does not return the refresh token when not expiring' do
      @access_token.stub(:expires?) { false }
      @access_token.stub(:refresh_token) { 'XXX' }
      subject.credentials['refresh_token'].should be_nil
      subject.credentials.should_not have_key('refresh_token')
    end
  end
  
  describe '#extra' do
    before :each do
      @raw_info = { 'name' => 'Fred Smith' }
      subject.stub(:raw_info) { @raw_info }
    end
    
    it 'returns a Hash' do
      subject.extra.should be_a(Hash)
    end
    
    it 'contains raw info' do
      subject.extra.should eq({ 'raw_info' => @raw_info })
    end
  end
end
