module Bdge
  class App < Sinatra::Base
    DB = Sequel.connect(ENV["DATABASE_URL"])

    register Sinatra::RespondWith

    set :version, "0.0.1"

    set :haml, format: :html5, escape_html: true, attr_wrapper: '"'
    set :json_encoder, Yajl::Encoder

    set :hostname, "bdge.co"
    set :target_host, "polar-wave-4365.herokuapp.com"

    get "/" do
      haml :root
    end

    get "/version" do
      json version: settings.version
    end

    get "/users/:username" do
      @user = User.where(username: params[:username]).first
      if @user
        respond_to do |f|
          f.json { json username: @user.username,
                        url: "https://#{settings.target_host}/#{@user.username}",
                        website: @user.website,
                        badges: @user.achievements }
        end
      else
        404
      end
    end

    get "/:hash" do
      @achievement = Achievement.where(short_hash: params[:hash]).first
      if @achievement
        respond_to do |f|
          f.json { json url: "http://#{settings.hostname}/#{params[:hash]}",
                        redirect_url: "https://#{settings.target_host}/#{@achievement.user[:username]}/badges/#{@achievement[:slug]}" }
          f.html { redirect "https://#{settings.target_host}/#{@achievement.user[:username]}/badges/#{@achievement[:slug]}" }
        end
      else
        404
      end
    end

    # Model definitions

    class User < Sequel::Model
      one_to_many :achievements
    end

    class Badge < Sequel::Model
    end

    class Achievement < Sequel::Model
      many_to_one :user
      many_to_one :badge

      def to_json
        Yajl::Encoder.encode({
          badge: {
            name: self.badge.name
          },
          url: "http://#{Bdge::App.settings.hostname}/#{self.short_hash}"
        })
      end
    end
  end
end
