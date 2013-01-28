worker_processes 2
preload_app true
timeout 30

before_fork do |server, worker|
  Bdge::App::DB.disconnect
end
