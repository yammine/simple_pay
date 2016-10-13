defmodule SimplePay do
  use Application

  @event_store SimplePay.EventStore

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      # Start the Ecto repository
      supervisor(SimplePay.Repo, []),
      # Start EventStore repo
      worker(Extreme, [Application.get_env(:extreme, :event_store), [name: @event_store]]),
      supervisor(SimplePay.Endpoint, []),
      supervisor(SimplePay.Wallet.Supervisor, []),
    ]

    opts = [strategy: :one_for_one, name: SimplePay.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Hot reloading
  def config_change(changed, _new, removed) do
    SimplePay.Endpoint.config_change(changed, removed)
    :ok
  end
end
