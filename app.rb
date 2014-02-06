require 'sinatra'
require 'yelpster'
require 'foursquare2'
require 'pry'
require 'mongo'

include Mongo

configure do
  set :client, Foursquare2::Client.new(:client_id => ENV['FOURSQUARE_CLIENT_ID'], :client_secret => ENV['FOURSQUARE_CLIENT_SECRET'])
  set :foursquare_api_version_string, "20140203"
  set :db, MongoClient.new("localhost", 27017).db("cheap-beer")
end

get '/pry' do
  bars_db = settings.db["bars"]
  binding.pry
end

get '/bars.json' do
  bars_db = settings.db["bars"]
  map_sw = "#{params[:sw_latitude]},#{params[:sw_longitude]}"
  map_ne = "#{params[:ne_latitude]},#{params[:ne_longitude]}"
  foursquare_response = settings.client.search_venues(sw: map_sw, ne: map_ne, categoryId: "4bf58dd8d48988d116941735", \
    intent: "browse", v: settings.foursquare_api_version_string)
  venues_array = foursquare_response.venues.map do |venue|
    hash = Hash.new
    hash[:name] = venue.name
    hash[:_id] = venue.id
    hash[:lat] = venue.location.lat
    hash[:lng] = venue.location.lng
    hash
  end
  return_array = venues_array.map do |venue|
    db_result = bars_db.find(:_id => venue[:_id]).to_a
    if db_result.empty?
      bars_db.insert(venue)
      venue
    else
      db_result.first
    end
  end
  response.headers['Content-Type'] = "application/json"
  return_array.to_json
end

get '/' do
  erb :index
end

def set_beer_for_bar(id, beer_json)
  bars_db = settings.db["bars"]
  bars_db.update({_id: id}, {"$set" => beer_json})
end
