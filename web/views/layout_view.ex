defmodule Twitterer.LayoutView do
  use Twitterer.Web, :view

  import Plug.Conn

  def is_signed_in(conn) do
    get_session(conn, :user_id) != nil
  end
end
