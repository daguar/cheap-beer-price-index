require 'sinatra'
require 'yelpster'
require 'foursquare2'
require 'pry'

configure do
  set :client, Foursquare2::Client.new(:client_id => ENV['FOURSQUARE_CLIENT_ID'], :client_secret => ENV['FOURSQUARE_CLIENT_SECRET'])
  set :foursquare_api_version_string, "20140203"
end

get '/bars.json' do
  response.headers['Content-Type'] = "application/json"
  map_sw = "#{params[:sw_latitude]},#{params[:sw_longitude]}"
  map_ne = "#{params[:ne_latitude]},#{params[:ne_longitude]}"
  response = settings.client.search_venues(sw: map_sw, ne: map_ne, categoryId: "4bf58dd8d48988d116941735", intent: "browse", \
    v: settings.foursquare_api_version_string)
  venues_array = response.venues.map do |venue|
    hash = Hash.new
    hash[:name] = venue.name
    hash[:id] = venue.id
    hash[:lat] = venue.location.lat
    hash[:lng] = venue.location.lng
    hash
  end
  puts venues_array.length
  venues_array.to_json
end

get '/' do
  erb :index
end
