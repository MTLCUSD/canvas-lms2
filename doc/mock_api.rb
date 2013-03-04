#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'pp'
require 'json'

post '/api/messages/fromcanvas' do
  data = JSON.parse(request.body.read.to_s)
  logger.info data
  pp data
end