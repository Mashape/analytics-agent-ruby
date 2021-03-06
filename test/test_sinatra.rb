require 'sinatra'
require 'sinatra/base'
require 'rack'
require 'helper'


class TestSinatra < MiniTest::Test
  @zmq_pull = nil

  def app
    Sinatra.new do
      register MashapeAnalytics::Frameworks::Sinatra

      mashapeAnalytics! 'MY-API-KEY', host: @@host, send_body: true

      get('/get') { 'GET Endpoint' }
      post('/post') { 'POST Endpoint' }
    end
  end

  def setup
    # Create our socket server
    @zmq_pull = zmq_pull_socket(@@host)
  end

  def teardown
    MashapeAnalytics::Capture.disconnect
    @zmq_pull.close if @zmq_pull != nil
  end

  should 'send ALF on GET /get?query=test request' do
    request = Rack::MockRequest.new(app)
    response = request.get('/get?query=test')

    version, message = @zmq_pull.recv.split(' ', 2)
    alf = JSON.parse(message)

    assert_ruby_agent alf

    entry = alf['har']['log']['entries'].first
    assert_entry_request entry, 'GET', 'http://example.org/get?query=test'
    assert_entry_response entry, 200, 86
  end

  should 'send ALF on POST /post request' do
    request = Rack::MockRequest.new(app)
    response = request.post('/post')

    version, message = @zmq_pull.recv.split(' ', 2)
    alf = JSON.parse(message)

    assert_ruby_agent alf

    entry = alf['har']['log']['entries'].first
    assert_entry_request entry, 'POST', 'http://example.org/post'
    assert_entry_response entry, 200, 87
  end


end
