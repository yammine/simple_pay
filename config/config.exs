# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :simple_pay,
  ecto_repos: [SimplePay.Repo]

# Configures the endpoint
config :simple_pay, SimplePay.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "FAGOoT4KAS9/9nBVf8H3OYu2Rm9G6cxuPOUc0su+pZE4c/wJu5TJqEgIfxjYAHO+",
  render_errors: [view: SimplePay.ErrorView, accepts: ~w(html json)],
  pubsub: [name: SimplePay.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
