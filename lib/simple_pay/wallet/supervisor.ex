defmodule SimplePay.Wallet.Supervisor do
  use Supervisor

  alias SimplePay.Wallet.Aggregate

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      worker(Aggregate, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def add_child(wallet_id) do
    Supervisor.start_child(__MODULE__, [wallet_id])
  end
end
