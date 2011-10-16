require 'bundler/setup'
require 'rspec'
require 'omniauth/test'

RSpec.configure do |config|
  config.extend OmniAuth::Test::StrategyMacros, :type => :strategy
end
