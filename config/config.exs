# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :twitterer, Twitterer.Endpoint,
  url: [host: "localhost"],
  root: Path.dirname(__DIR__),
  secret_key_base: "VxFsNBHy2qINHXrf7i/gIxXo23YfXRULe2F3TfhLqghRONm3CqJltjPrNJNI4dQQ",
  debug_errors: false,
  pubsub: [name: Twitterer.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure our Twitter OAuth credentials
config :twitterer,
  oauth_consumer_key: System.get_env("TWITTER_OAUTH_CONSUMER_KEY"),
  oauth_consumer_secret: System.get_env("TWITTER_OAUTH_CONSUMER_SECRET"),
  oauth_access_token: System.get_env("TWITTER_OAUTH_ACCESS_TOKEN"),
  oauth_access_token_secret: System.get_env("TWITTER_OAUTH_ACCESS_TOKEN_SECRET")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
