defmodule Twitterer.MonitorController do
  require Logger
  @moduledoc """
  This controller handles setting up the initial monitoring channel between
  the client and the backend.
  """

  use Twitterer.Web, :controller

  plug :action

  @doc """
  This is the action that receives the initial hashtag to monitor and sets up
  the channel between the client and the backend.

  POST /monitor
  """
  def index(conn, %{"start_form" => %{"hashtag" => hashtag}} = _params) when is_binary(hashtag) and byte_size(hashtag) > 1 do
    render conn, "index.html", hashtag: hashtag, user_info: get_session(conn, :user_info)
  end

  # This action will only match if the start_form form with a "hashtag" element
  # wasn't sent in the request. Redirect back to the main page with an error.
  def index(conn, _params) do
    conn
    |> put_flash(:error, "Please enter a hashtag to begin.")
    |> redirect to: "/"
  end

end