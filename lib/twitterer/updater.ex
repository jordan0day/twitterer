defmodule Twitterer.Updater do
  alias Twitterer.Search

  def start_link(search_pid, auth_info) do
    pid = spawn_link(__MODULE__, :start_update_loop, [search_pid, auth_info])

    {:ok, pid}
  end

  def start_update_loop(search_pid, auth_info) do
    # Set up ExTwitter for the current process
    ExTwitter.configure(:process, [
      consumer_key: Application.get_env(:twitterer, :oauth_consumer_key),
      consumer_secret: Application.get_env(:twitterer, :oauth_consumer_secret),
      # access_token: Application.get_env(:twitterer, :oauth_access_token),
      # access_token_secret: Application.get_env(:twitterer, :oauth_access_token_secret)])
      access_token: auth_info["token"],
      access_token_secret: auth_info["secret"]])

    hashtags = Search.get_hashtags(search_pid)
    do_update_loop(search_pid, hashtags, [])
  end

  defp do_update_loop(search_pid, [], _searched) do
    # We've searched through all the hashtags. Re-load the list of hashtags
    # from the Search GenServer (in case it's been updated) and re-start the
    # update loop.

    hashtags = Search.get_hashtags(search_pid)
    do_update_loop(search_pid, hashtags, [])
  end

  defp do_update_loop(search_pid, to_search, searched) do
    [current_hashtag | rest] = to_search

    receive do
    after 5000 ->
      results = ExTwitter.search(URI.encode("##{current_hashtag}"), [count: 5])

      Twitterer.Search.search_results(search_pid, current_hashtag, results)
    end

    do_update_loop(search_pid, rest, [current_hashtag | searched])
  end
end