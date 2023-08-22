# server.rb
require 'sinatra'
require "sinatra/namespace"
require 'faraday'

ADIANTE_CNPJ="33013052000151"
ADIANTE_TOKEN_INTEGRACAO="1N2LBfX87Zp7ZBH12eF2yUa0N5d8OcaRNIsVn192"
ADIANTE_GATEWAY_API="https://dev-gateway.adiantesa.com"
ADIANTE_GATEWAY_ARQ="https://dev-gateway.adiantesa.com"

enable :sessions

class AdianteParser

  attr_accessor :status, :data, :raw_response

  def initialize(raw_response)
    @raw_response = raw_response
    @status = raw_response.status
    @data = raw_response.body
  end

  def isOk?
    puts @raw_response.status
    (@raw_response.status == 200)
  end

  #private

  def parsed_json
    @parsed_json ||= JSON.parse(@raw_response.body, symbolize_names: true)
    #JSON.parse(@raw_response.body, symbolize_names: true)
  end

  def to_h
    {
      status: @status,
      data: parsed_json
    }
  end

  def as_json(*)
    data = {
      status: @status,
      data: @data,
    }
    data[:errors] = "format error" if @status.nil?
    data
  end

end

class Jedi

  attr_accessor :token

  def headers
    {
      "Content-Type" => "application/json",
      "Authorization" => "Basic #{ADIANTE_TOKEN_INTEGRACAO}",
      "customer_ip" => "192.174.23.1",
      "user_type" => "customer",
    }
  end

  def headers_bearer(token)
    {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{token}",
      "customer_ip" => "192.174.23.1",
      "user_type" => "customer",
    }
  end

end


# Endpoints
get '/' do
  #'Welcome to BookList!'
  puts ">>>>>" * 20
  puts "Inicio Login antecipa"
  body_login = {:document => "17642368000156", :email => "fabio@certus.inf.br" }.to_json
  headers = Jedi.new().headers
  response = Faraday.post("#{ADIANTE_GATEWAY_API}/authentication/v2/customer/login/integration", body_login, headers)
  result = AdianteParser.new(response).to_h
  #resp1 = AdianteParser.new(response).to_json
  #puts resp1
  session['token'] = result[:data][:token]

  #puts result
  #puts result[:data][:payload][:id]
  #puts result[:data][:token]
  
  content_type :json
  { data: session['token'] }.to_json
  

  #serialize(result)



  

end

namespace '/api/v1' do

  before do
    content_type 'application/json'
  end

  helpers do
    def base_url
      # @base_url ||= "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
      @base_url ||= ADIANTE_GATEWAY_API
    end

    def base_token
      @token ||= session['token']
    end

    def json_params
      JSON.parse(request.body.read)
    rescue => e
      puts e
      halt 400, { message: 'Invalid JSON' }.to_json
    end

    #def book
    #  @book ||= Book.where(id: params[:id]).first
    #end

    def halt_if_not_found!
      halt(404, { message: 'Book Not Found'}.to_json) unless book
    end

    def serialize(book)
      BookSerializer.new(book).to_json
    end
  end

  get '/list_data' do
    headers_by_bearer = Jedi.new().headers_bearer(2121)
    puts headers_by_bearer
    response = Faraday.get("#{ADIANTE_GATEWAY_API}/customer/v2/data", nil, headers_by_bearer)
    result = AdianteParser.new(response).to_h

    content_type :json
    result.to_json

  end

  get '/books/:id' do |id|
    halt_if_not_found!
    #serialize(book)
  end

  # post '/books' do
  #   #book = Book.new(json_params)
  #   halt 422, serialize(book) unless book.save
  #   response.headers['Location'] = "#{base_url}/api/v1/books/#{book.id}"
  #   status 201
  # end

  # patch '/books/:id' do |id|
  #   halt_if_not_found!
  #   halt 422, serialize(book) unless book.update_attributes(json_params)
  #   serialize(book)
  # end

  # delete '/books/:id' do |id|
  #   book.destroy if book
  #   status 204
  # end

end
