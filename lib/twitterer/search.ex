defmodule Twitterer.Search do
  use GenServer

  ## Client API

  @spec start_link(pid, Map.t, [String.t]) :: {:ok, Map.t}
  def start_link(channel_pid, auth_info, hashtags) do
    state = %{
      channel_pid: channel_pid,
      auth_info: auth_info,
      hashtags: hashtags
    }
    
    GenServer.start_link(__MODULE__, state)
  end

  @doc """
  Get the list of hashtags this Search server is searching
  """
  def get_hashtags(search_pid) do
    GenServer.call(search_pid, :get_hashtags)
  end

  @doc """
  Inform the Search server that results for a particular hashtag have been
  updated.
  """
  def search_results(search_pid, hashtag, results) do
    GenServer.cast(search_pid, {:search_results, hashtag, results})
  end

  def add_hashtag(search_pid, hashtag) do
    GenServer.cast(search_pid, {:add_hashtag, hashtag})
  end

  def remove_hashtag(search_pid, hashtag) do
    GenServer.cast(search_pid, {:remove_hashtag, hashtag})
  end

  ## Server API

  def handle_call(:get_hashtags, _from, state) do
    {:reply, state[:hashtags], state}
  end

  def handle_cast({:add_hashtag, hashtag}, state) do
    # Don't add the hashtag if it's already present
    unless Enum.any?(state[:hashtags], &(&1 == hashtag)) do
      hashtags = [hashtag | state[:hashtags]]

      state = Map.put(state, :hashtags, hashtags)
    end

    {:noreply, state}
  end

  def handle_cast({:remove_hashtag, hashtag}, state) do
    hashtags = List.delete(state[:hashtags], hashtag)

    {:noreply, Map.put(state, :hashtags, hashtags)}
  end

  def handle_cast({:search_results, hashtag, results}, state) do
    message = %{hashtag: hashtag, results: [:test, :hello, :world]}

    # Since Phoenix Channels are just GenServers, we can send our results as
    # a regular message, and pick them up in the channel's `handle_info/2`.
    send state[:channel_pid], {:hashtag_updated, hashtag, results}

    {:noreply, state}
  end

  def init(state) do
    # Spawn a supervisor to handle the process that actually goes and hits the
    # twitter search API.
    import Supervisor.Spec

    children = [
      worker(Twitterer.Updater, [self, state[:auth_info]])
    ]

    {:ok, supervisor_pid} = Supervisor.start_link(children, strategy: :one_for_one)

    {:ok, Map.put(state, :supervisor_pid, supervisor_pid)}
  end
end