defmodule SimplePay.Wallet.Reader do
  use GenServer

  alias SimplePay.{Wallet, Repo, Utilities}
  alias Events.{WalletCreated, MoneyDeposited, MoneyWithdrawn, WithdrawDeclined}

  @default_state %{ event_store: SimplePay.EventStore, stream: nil, last_event: nil, balance: nil,
                    subscription_ref: nil, id: nil }

  def start_link(wallet) do
    GenServer.start_link(__MODULE__, wallet, name: via_tuple(wallet))
  end

  def init(wallet_id) do
    stream = "wallet-" <> to_string(wallet_id)
    %Wallet{last_event_processed: last_event, balance: balance} = wallet = Repo.get!(Wallet, wallet_id) # Our latest snapshot

    state = %{@default_state | stream: stream, last_event: last_event, balance: balance, id: wallet.id}
    GenServer.cast(self, :subscribe)

    {:ok, state}
  end

  def handle_cast(:subscribe, state) do
    # Read only unprocessed events and stay subscribed
    {:ok, subscription} = Extreme.read_and_stay_subscribed(state.event_store, self, state.stream, state.last_event + 1)
    # Monitor the subscription so we can resubscribe in the case of a crash
    ref = Process.monitor(subscription)
    {:noreply, %{state|subscription_ref: ref}}
  end

  @doc """
  Deals with the events pushed by our EventStore & updates state accordingly.
  """
  def handle_info({:on_event, push}, state) do
    case push.event.event_type do
      "Elixir.Events.MoneyDeposited" ->
        data = :erlang.binary_to_term(push.event.data)
        update_params = %{balance: state.balance + data.amount, last_event_processed: state.last_event + 1}
        wallet = Repo.get!(Wallet, state.id) |> Wallet.update_changeset(update_params) |> Repo.update!
        {:noreply, %{state | balance: wallet.balance, last_event: wallet.last_event_processed}}
      "Elixir.Events.MoneyWithdrawn" ->
        data = :erlang.binary_to_term(push.event.data)
        update_params = %{balance: state.balance - data.amount, last_event_processed: state.last_event + 1}
        wallet = Repo.get!(Wallet, state.id) |> Wallet.update_changeset(update_params) |> Repo.update!
        {:noreply, %{state | balance: wallet.balance, last_event: wallet.last_event_processed}}
      "Elixir.Events.WithdrawDeclined" ->
        IO.puts "Withdraw declined - Balance: $#{state.balance / 100}"
        update_params = %{last_event_processed: state.last_event + 1}
        wallet = Repo.get!(Wallet, state.id) |> Wallet.update_changeset(update_params) |> Repo.update!
        {:noreply, %{state | last_event: wallet.last_event_processed}}
      _ ->
        update_params = %{last_event_processed: state.last_event + 1}
        wallet = Repo.get!(Wallet, state.id) |> Wallet.update_changeset(update_params) |> Repo.update!
        {:noreply, %{state | last_event: wallet.last_event_processed}}
    end
  end

  defp via_tuple(wallet) do
    {:via, :gproc, {:n, :l, {:wallet, wallet}}}
  end
end
