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

get '/' do
  erb :index
end

get '/bars.json' do
  bars_db = settings.db["bars"]
  map_sw = "#{params[:sw_latitude]},#{params[:sw_longitude]}"
  map_ne = "#{params[:ne_latitude]},#{params[:ne_longitude]}"
  bar_finder = FoursquareBarFinder.new(client: settings.client, version_string: settings.foursquare_api_version_string)
  venues_array = bar_finder.bounding_box(sw: map_sw, ne: map_ne)
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

get '/bars/:id' do
  bars_db = settings.db["bars"]
  @bar = bars_db.find(:_id => params[:id]).to_a.first
  # TODO: Catch if not found in DB
  if @bar["beer_data"]
    erb :bar
  else
    erb :bar_form
  end
end

post '/bars/:id' do
  beer_form_data = params.select do |key, value|
    ["brand", "other-brand", "draft", "price-dollars", "price-cents", "comments"].include?(key)
  end
  if BeerHelper.valid_form_data?(beer_form_data)
    clean_beer_data = BeerHelper.clean_form_data(beer_form_data)
    bars_db = settings.db["bars"]
    bars_db.update({_id: params[:id]}, {"$set" => {beer_data: clean_beer_data} })
    redirect to('/')
  else
    # Do something else, then redirect back to page
    redirect to("/bars/#{params[:id]}")
  end  
end

module BeerHelper
  extend self
  def valid_form_data?(params)
    true
  end

  def clean_form_data(form_data)
    clean_hash = Hash.new
    clean_hash["brand"] = form_data["other-brand"].empty? ? form_data["brand"] : form_data["other-brand"]
    clean_hash["price"] = form_data["price-dollars"] + "." + form_data["price-cents"]
    clean_hash["draft"] = form_data["hash"]
    clean_hash["comments"] = form_data["comments"]
    clean_hash
  end
end

class FoursquareBarFinder
  def initialize(params)
    @client = params[:client]
    @version_string = params[:version_string]
  end

  def bounding_box(params)
    foursquare_response = @client.search_venues(sw: params[:sw], ne: params[:ne], categoryId: "4bf58dd8d48988d116941735", \
      intent: "browse", v: @version_string)
    venues_array = foursquare_response.venues.map do |venue|
      hash = Hash.new
      hash[:name] = venue.name
      hash[:_id] = venue.id
      hash[:lat] = venue.location.lat
      hash[:lng] = venue.location.lng
      hash
    end
    venues_array
  end
end