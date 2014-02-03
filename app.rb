require 'sinatra'
require 'yelpster'
require 'foursquare2'

configure do
  set :client, Foursquare2::Client.new(:client_id => ENV['FOURSQUARE_CLIENT_ID'], :client_secret => ENV['FOURSQUARE_CLIENT_SECRET'])
end

get '/bars.json' do
  #return [] unless [:sw_latitude, :sw_longitude, :ne_latitude, :ne_longitude].all? { |key| params.key?(key) }
  #params[:category_filter] = "bars"
  puts client
  puts params
  map_sw = [params[:sw_latitude], params[:sw_longitude]]
  map_ne = [params[:ne_latitude], params[:ne_longitude]]
  response = client.search_venues(sw: map_sw, ne: map_ne)
  response.to_json
end

get '/' do
  erb :index
end
