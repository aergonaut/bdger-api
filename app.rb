module Bdge
  class App < Sinatra::Base
    DB = Sequel.connect(ENV["DATABASE_URL"])

    register Sinatra::RespondWith

    set :version, "0.0.1"

    set :haml, format: :html5, escape_html: true, attr_wrapper: '"'
    set :json_encoder, Yajl::Encoder

    set :hostname, "bdge.co"
    set :target_host, "www.bdger.com"

    get "/" do
      redirect "https://#{settings.target_host}"
    end

    get "/version" do
      json version: settings.version
    end

    get "/badges" do
      @badges = Badge.all
      respond_to do |f|
        f.json { json @badges }
        f.html { redirect "https://#{settings.target_host}/badges" }
      end
    end

    get "/badges/:slug" do
      @badge = Badge.where(slug: params[:slug]).first
      if @badge
        respond_to do |f|
          f.json { json @badge }
          f.html { redirect "https://#{settings.target_host}/badges/#{@badge[:slug]}" }
        end
      else
        404
      end
    end

    get "/users/:username" do
      @user = User.where(username: params[:username]).first
      if @user
        respond_to do |f|
          f.json { json @user }
          f.html { redirect "https://#{settings.target_host}/#{@user[:username]}" }
        end
      else
        404
      end
    end

    get "/:hash" do
      @achievement = Achievement.where(short_hash: params[:hash]).first
      if @achievement
        respond_to do |f|
          f.json { json @achievement }
          f.html { redirect "https://#{settings.target_host}/#{@achievement.user[:username]}/badges/#{@achievement[:slug]}" }
        end
      else
        404
      end
    end

    # Model definitions

    class User < Sequel::Model
      one_to_many :achievements

      def to_json
        Yajl::Encoder.encode({
          username: self[:username],
          url: "https://#{Bdge::App.settings.target_host}/#{self[:username]}",
          website: self[:website],
          badges: self.achievements
        })
      end
    end

    class Badge < Sequel::Model
      one_to_many :achievements

      def to_json
        Yajl::Encoder.encode({
          name: self[:name],
          url: "https://#{Bdge::App.settings.target_host}/badges/#{self[:slug]}"
        })
      end
    end

    class Achievement < Sequel::Model
      many_to_one :user
      many_to_one :badge

      def to_json
        Yajl::Encoder.encode({
          badge: {
            name: self.badge[:name]
          },
          url: "http://#{Bdge::App.settings.hostname}/#{self[:short_hash]}",
          redirect_url: "https://#{Bdge::App.settings.target_host}/#{self.user[:username]}/badges/#{self[:slug]}"
        })
      end
    end
  end
end
