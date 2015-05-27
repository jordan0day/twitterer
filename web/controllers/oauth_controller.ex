defmodule Twitterer.OauthController do
  require Logger
  @moduledoc """
  This controller handles OAuth interations with Twitter, enabling us to use
  the Twitter API on the user's behalf.
  """
  use Twitterer.Web, :controller

  plug :action

  @doc """
  This is the action that displays the "Sign in with Twitter" screen.
  
  GET /oauth
  """
  def index(conn, _params) do
    render conn, "index.html"
  end

  @doc """
  This is the action that is called by the link on the "Sign in with Twitter"
  screen. If retrieves an access token from twitter using our application's
  credentials, and then redirects the user to twitter to authorize the
  application.

  GET /oauth/redirect
  """
  def twitter_redirect(conn, _params) do
    # Step 1: Send a POST to https://api.twitter.com/oauth/request_token
    # to initiate the OAuth token request
    request_token_url = "https://api.twitter.com/oauth/request_token"
    authenticate_url = "https://api.twitter.com/oauth/authenticate"

    header = get_oauth_authorization_header(request_token_url, Application.get_env(:twitterer, :oauth_access_token), Application.get_env(:twitterer, :oauth_access_token_secret))

    case HTTPoison.post(request_token_url, "", [header]) do
      {:ok, %{status_code: 200} = response} ->       
        # Response body is of the form:
        # oauth_token=NPcudxy0yU5T3tBzho7iCotZ3cnetKwcTIRlX0iwRl0&
        # oauth_token_secret=veNRnAWe6inFuo8o2u8SLLZLjolYDmDP7SzL0YfYI&
        # oauth_callback_confirmed=true
        %{"oauth_token" => token, "oauth_token_secret" => secret} = URI.decode_query(response.body)

        # Step 2: Redirect the user to twitter to sign-in & authorize the
        # application.
        # Save the token and secret in the session data
        # Don't do this for a real-world application!
        conn
        |> put_session(:token, token)
        |> put_session(:secret, secret)
        |> redirect external: authenticate_url <> "?oauth_token=" <> token

      {result, resp} ->
        Logger.error "Something went wrong requesting a token. Result: #{inspect result}\nResponse: #{inspect resp}"
        conn
        |> put_flash(:error, "An error occurred signing in. Please try again.")
        |> redirect to: "/oauth"
    end    
  end

  @doc """
  This is the action that will be triggered by the twitter authorization
  callback, after the user has signed in and authorized our application.

  GET /oauth/callback
  """
  def twitter_callback(conn, %{"oauth_token" => token, "oauth_verifier" => verifier}) do
    access_token_url = "https://api.twitter.com/oauth/access_token"

    # Retrieve oauth token info from the session
    token = get_session(conn, :token)
    secret = get_session(conn, :secret)
    header = get_oauth_authorization_header(access_token_url, token, secret)

    body = "oauth_verifier=" <> URI.encode_www_form(verifier)

    headers = [{"Content-Type", "application/x-www-form-urlencoded"}, header]

    case HTTPoison.post(access_token_url, body, headers) do
      {:ok, %{status_code: 200} = response} ->
        # Response body is of the form:
        # oauth_token=NPcudxy0yU5T3tBzho7iCotZ3cnetKwcTIRlX0iwRl0&
        # oauth_token_secret=veNRnAWe6inFuo8o2u8SLLZLjolYDmDP7SzL0YfYI&
        # user_id=18676674&
        # screen_name=jordan0day

        body = URI.decode_query(response.body)
        conn
        |> put_session(:token, body["oauth_token"])
        |> put_session(:secret, body["oauth_token_secret"])
        |> put_session(:user_id, body["user_id"])
        |> put_session(:screen_name, body["screen_name"])
        |> put_flash(:info, "Sign-in successful!")
        |> redirect to: "/"
      {result, resp} ->
        Logger.error "Something went wrong retrieving an access token. Result: #{inspect result}\nResponse: #{inspect resp}"
        conn
        |> put_flash(:error, "An error occurred signing in. Please try again.")
        |> redirect to: "/oauth"
    end
  end

  def logout(conn, _params) do
    conn
    |> delete_session(:token)
    |> delete_session(:secret)
    |> delete_session(:user_id)
    |> delete_session(:screen_name)
    |> put_flash(:info, "Logged out")
    |> redirect to: "/oauth"
  end

  # Generate the OAuth Authorization header with signature, used for making
  # API requests to Twitter.
  defp get_oauth_authorization_header(url, token, token_secret) do
    credentials = OAuther.credentials(
      consumer_key: Application.get_env(:twitterer, :oauth_consumer_key),
      consumer_secret: Application.get_env(:twitterer, :oauth_consumer_secret),
      token: token,
      token_secret: token_secret)

    params = OAuther.sign("post", url, [], credentials)
    {header, _} = OAuther.header(params)
    header
  end
end