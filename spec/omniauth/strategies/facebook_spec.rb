require 'spec_helper'
require 'omniauth-facebook'

describe OmniAuth::Strategies::Facebook do
  subject do
    OmniAuth::Strategies::Facebook.new(nil, @options || {})
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
    it 'is empty by default' do
      subject.authorize_params.should be_empty
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
      @raw_info ||= {}
      subject.stub(:raw_info) { @raw_info }
    end
    
    it 'returns the username as nickname' do
      @raw_info['username'] = 'fredsmith'
      subject.info['nickname'].should eq('fredsmith')
    end
    
    it 'returns the email' do
      @raw_info['email'] = 'fred@smith.com'
      subject.info['email'].should eq('fred@smith.com')
    end
    
    it 'returns the first name' do
      @raw_info['first_name'] = 'Fred'
      subject.info['first_name'].should eq('Fred')
    end
    
    it 'returns the last name' do
      @raw_info['last_name'] = 'Smith'
      subject.info['last_name'].should eq('Smith')
    end
    
    it 'returns the facebook avatar url' do
      @raw_info['id'] = '321'
      subject.info['image'].should eq('http://graph.facebook.com/321/picture')
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
end
