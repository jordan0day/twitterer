defmodule Twitterer.MonitorChannel do
  use Phoenix.Channel

  def join("monitor:" <> hashtag, auth_msg, socket) do
    IO.puts "monitoring hashtag #{inspect hashtag}"
    if authorized?(auth_msg) do
      case socket.assigns[:searcher_pid] do
        nil ->
          {:ok, pid} = Twitterer.Search.start_link(self, auth_msg, [hashtag])
          socket = assign(socket, :searcher_pid, pid)
        pid ->
          Twitterer.Search.add_hashtag(pid, hashtag)
      end

      {:ok, socket}
    else
      IO.puts "unauthorized!"
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in(:hashtag_updated, %{hashtag: hashtag, results: results}, socket) do
    IO.puts "Pushing new results for #{inspect hashtag}"

    {:noreply, socket}
  end

  def handle_info({:hashtag_updated, hashtag, results}, state) do
    IO.puts "in the handle info for hashtag: #{inspect hashtag}"

    {:noreply, state}
  end

  def terminate(message, socket) do
    IO.puts "Channel terminated. Message: #{inspect message}"

    # Shut down the searcher
    case socket.assigns[:searcher_pid] do
      nil -> :ok # Don't need to do anything
      pid ->
        Process.exit(pid, :normal)
        :ok
    end
  end

  defp authorized?(nil), do: false

  defp authorized?(auth_msg) do
    auth_msg["user_id"] != nil && auth_msg["screen_name"] != nil && auth_msg["token"] != nil && auth_msg["secret"] != nil
  end
end