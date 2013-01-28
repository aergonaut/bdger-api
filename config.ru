require "rubygems"
require "bundler"
Bundler.require :default, ENV["RACK_ENV"]
require "./app"

map "/" do
  run Bdge::App
end
