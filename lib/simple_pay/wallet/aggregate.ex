defmodule SimplePay.Wallet.Aggregate do
  use GenServer
  import Ecto.Query

  alias SimplePay.{Wallet, Repo, Utilities}
  alias Events.{WalletCreated, MoneyDeposited, MoneyWithdrawn, WithdrawDeclined}

  @default_state %{ event_store: SimplePay.EventStore, stream: nil, last_event: nil, balance: nil,
                    subscription_ref: nil, id: nil }
  @timeout 60_000 # Default 60 second timeout

  ##################
  # Initialization #
  ##################

  def start_link(wallet_id) do
    GenServer.start_link(__MODULE__, wallet_id, name: via_tuple(wallet_id))
  end

  def init(wallet_id) do
    stream = "wallet-" <> to_string(wallet_id)
    %Wallet{last_event_processed: last_event, balance: balance} = wallet = Repo.get!(Wallet, wallet_id) # Catastrophic failure if this doesn't match

    state = %{@default_state | stream: stream, last_event: last_event, balance: balance, id: wallet.id}
    GenServer.cast(self, :subscribe)

    {:ok, state}
  end

  ##################
  #       API      #
  ##################

  def withdraw(pid, amount), do: GenServer.call(pid, {:attempt_command, {:withdraw, amount}})
  def deposit(pid, amount), do: GenServer.call(pid, {:attempt_command, {:deposit, amount}})

  ##################
  #    Callbacks   #
  ##################

  def handle_cast(:subscribe, state) do
    # Read only unprocessed events and stay subscribed
    {:ok, subscription} = Extreme.read_and_stay_subscribed(state.event_store, self, state.stream, state.last_event + 1)
    # Monitor the subscription so we can resubscribe in the case of a crash
    ref = Process.monitor(subscription)
    {:noreply, %{state|subscription_ref: ref}}
  end

  def handle_call({:attempt_command, {:deposit, amount}}, _from, state) do
    event = %{%MoneyDeposited{} | id: state.id, amount: amount, transaction_date: DateTime.utc_now }
    {:reply, write_event(event, state), state}
  end

  def handle_call({:attempt_command, {:withdraw, amount}}, _from, state) do
    new_balance = state.balance - amount
    event = case new_balance < 0.0 do
      false ->
        %{%MoneyWithdrawn{} | id: state.id, amount: amount, transaction_date: DateTime.utc_now }
      true ->
        %{%WithdrawDeclined{} | id: state.id, amount: amount, transaction_date: DateTime.utc_now}
    end
    {:reply, write_event(event, state, state.last_event), state}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, %{subscription_ref: ref} = state) do
    GenServer.cast self, :subscribe
    {:noreply, %{state|subscription_ref: nil}}
  end

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
        IO.puts "Withdraw declined yo"
        update_params = %{last_event_processed: state.last_event + 1}
        wallet = Repo.get!(Wallet, state.id) |> Wallet.update_changeset(update_params) |> Repo.update!
        {:noreply, %{state | last_event: wallet.last_event_processed}}
      _ ->
        update_params = %{last_event_processed: state.last_event + 1}
        wallet = Repo.get!(Wallet, state.id) |> Wallet.update_changeset(update_params) |> Repo.update!
        {:noreply, %{state | last_event: wallet.last_event_processed}}
    end
  end

  ##################
  #     Utility    #
  ##################

  defp write_event(event, state, expected_version \\ -2) do
    Extreme.execute(state.event_store, Utilities.write_events(state.stream, [event], expected_version))
  end

  defp update_state(event = %MoneyDeposited{}, state) do
    %{state | balance: state.balance + event.amount}
  end

  defp via_tuple(wallet) do
    {:via, :gproc, {:n, :l, {:wallet, wallet}}}
  end
end
