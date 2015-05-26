defmodule Twitterer.PageController do
  use Twitterer.Web, :controller

  plug :action

  def index(conn, _params) do
    render conn, "index.html"
  end
end
