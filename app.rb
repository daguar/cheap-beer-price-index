require 'sinatra'
require 'yelpster'

Yelp.configure(:consumer_key => ENV['CONSUMER_KEY'],\
  :consumer_secret => ENV['CONSUMER_SECRET'],\
  :token => ENV['TOKEN'],\
  :token_secret => ENV['TOKEN_SECRET'])

@@client = Yelp::Client.new

get '/bars.json' do
  #return [] unless [:sw_latitude, :sw_longitude, :ne_latitude, :ne_longitude].all? { |key| params.key?(key) }
  params[:category_filter] = "bars"
  request = Yelp::V2::Search::Request::BoundingBox.new(params)
  response = @@client.search(request)
  response.to_json
end

get '/' do
  erb :index
end
