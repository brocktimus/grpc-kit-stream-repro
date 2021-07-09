# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('./routeguide')

require 'socket'
require 'grpc_kit'
require 'pry'
require 'json'
require 'routeguide_services_pb'

class Server < Routeguide::RouteGuide::Service
  RESOURCE_PATH = './routeguide/routeguide.json'

  def initialize
    File.open(RESOURCE_PATH) do |f|
      features = JSON.parse(f.read)
      @features = Hash[features.map { |x| [x['location'], x['name']] }]
    end

    @route_notes = Hash.new { |h, k| h[k] = [] }
  end

  def list_features(rect, stream)
    GRPC.logger.info('===== list_features =====')

    loop do
      @features.each do |location, name|
        sleep 1
        if name.nil? || name == '' || !in_range(location, rect)
          next
        end

        pt = Routeguide::Point.new(location)
        resp = Routeguide::Feature.new(location: pt, name: name)
        GRPC.logger.info(resp)
        stream.send_msg(resp)
      end
    end
  end

  private

  def in_range(point, rect)
    longitudes = [rect.lo.longitude, rect.hi.longitude]
    left = longitudes.min
    right = longitudes.max

    latitudes = [rect.lo.latitude, rect.hi.latitude]
    bottom = latitudes.min
    top = latitudes.max
    (point['longitude'] >= left) && (point['longitude'] <= right) && (point['latitude'] >= bottom) && (point['latitude'] <= top)
  end

end

sock = TCPServer.new(50051)
opts = {}

if ENV['GRPC_INTERCEPTOR']
  require_relative 'interceptors/server_logging_interceptor'
  opts[:interceptors] = [LoggingInterceptor.new]
end

server = GrpcKit::Server.new(**opts)
server.handle(Server.new)

loop do
  conn = sock.accept
  server.run(conn)
end
