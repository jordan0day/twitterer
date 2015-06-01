defmodule Twitterer.Plugs.Auth do
  defmacro __using__(_) do
    quote do
      import Plug.Conn

      def require_user_session(conn, opts) do
        if get_session(conn, :user_info) == nil do
          conn
            |> Phoenix.Controller.put_flash(:error, "Login required")
            |> redirect(to: "/oauth")
            |> halt
        else
          conn
        end
      end
    end
  end
end