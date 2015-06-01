defmodule Twitterer.Router do
  use Twitterer.Web, :router
  use Twitterer.Plugs.Auth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
  end

  pipeline :authenticated do
    plug :require_user_session
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/oauth" do
    pipe_through :browser

    get "/", Twitterer.OauthController, :index
    get "/redirect", Twitterer.OauthController, :twitter_redirect
    get "/callback", Twitterer.OauthController, :twitter_callback
    post "/logout", Twitterer.OauthController, :logout
  end

  scope "/", Twitterer do
    pipe_through :browser # Use the default browser stack
    pipe_through :authenticated

    get "/", PageController, :index

    scope "/monitor" do
      post "/", MonitorController, :index
    end
  end

  socket "/monitor/ws", Twitterer do
    channel "monitor:*", MonitorChannel
  end

  # Other scopes may use custom stacks.
  # scope "/api", Twitterer do
  #   pipe_through :api
  # end
end
