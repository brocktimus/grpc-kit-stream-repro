# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('./routeguide')

require 'socket'
require 'grpc_kit'
require 'pry'
require 'json'
require 'routeguide_services_pb'

RESOURCE_PATH = './examples/routeguide/routeguide.json'
HOST = 'localhost'
PORT = 50051

def list_features(stub)
  GRPC.logger.info('===== list_features =====')
  rect = Routeguide::Rectangle.new(
    lo: Routeguide::Point.new(latitude: 400_000_000, longitude: -750_000_000),
    hi: Routeguide::Point.new(latitude: 420_000_000, longitude: -730_000_000),
  )

  stream = stub.list_features(rect)
  stream.each do |r|
    GRPC.logger.info("Found #{r.name} at #{r.location.inspect}")
  end
end

opts = {}

if ENV['GRPC_INTERCEPTOR']
  require_relative 'interceptors/client_logging_interceptor'
  opts[:interceptors] = [LoggingInterceptor.new]
elsif ENV['GRPC_TIMEOUT']
  opts[:timeout] = Integer(ENV['GRPC_TIMEOUT'])
end

sock = TCPSocket.new(HOST, PORT)
stub = Routeguide::RouteGuide::Stub.new(sock, **opts)

list_features(stub)
