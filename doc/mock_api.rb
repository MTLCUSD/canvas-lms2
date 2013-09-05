#!/usr/bin/env ruby
#Empowered
# sudo ./mock_api.rb -p 80

require 'rubygems'
require 'sinatra'
require 'pp'
require 'json'

post '/api/messages/fromcanvas' do
  data = JSON.parse(request.body.read.to_s)
  logger.info data
  pp data
end