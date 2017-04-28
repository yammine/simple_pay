defmodule SimplePay.Wallet.Aggregate do
  use GenServer
  require Logger

  alias SimplePay.{Wallet, Repo, Utilities}

  alias Commands.{CreateWallet, DepositMoney, WithdrawMoney}
  alias Events.{WalletCreated, MoneyDeposited, MoneyWithdrawn, WithdrawDeclined}

  @default_state %{ event_store: SimplePay.EventStore, stream: nil, last_event: nil, balance: nil,
                    subscription_ref: nil, id: nil }
  @timeout 60_000 # Default 60 second timeout TODO: Actually kill this genserver after @timeout of inactivity.

  @stream_doesnt_exist -1
  @stream_should_exist -4

  ##################
  # Initialization #
  ##################

  def start_link(wallet_id) do
    GenServer.start_link(__MODULE__, wallet_id, name: via_tuple(wallet_id))
  end

  def init(wallet_id) do
    stream = "wallet-" <> to_string(wallet_id)
    case Repo.get(Wallet, wallet_id) do
      %Wallet{last_event_processed: last_event, balance: balance} = wallet ->
        state = %{@default_state | stream: stream, last_event: last_event, balance: balance, id: wallet.id}
        GenServer.cast(self, :subscribe)

        {:ok, state}
      nil ->
        :ignore
    end
  end

  ##################
  #       API      #
  ##################

  def apply(pid, command) do
    meta = %EventMetadata{event_id: Extreme.Tools.gen_uuid}
    GenServer.cast(pid, {:attempt_command, command, meta})
  end

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

  # Failed due to too many retries
  def handle_cast({:attempt_command, command, %EventMetadata{retries: 0} = meta}, state) do
    Logger.warn("Failed following command due to too many retries:\n metadata: #{inspect meta}\n #{inspect command}")
    {:noreply, state}
  end

  def handle_cast({:attempt_command, %CreateWallet{id: id}, %EventMetadata{} = meta}, state) do
    event = %{%WalletCreated{} | id: id, guid: meta.event_id}
    case write_event(event, state, @stream_doesnt_exist) do
      {:error, :WrongExpectedVersion, _} ->
        Logger.warn("Attempted to create a Wallet with id: #{id} but it already exists.")
      {:ok, _response} ->
        Logger.info("Stream wallet-#{id} created.")
    end
    {:noreply, state}
  end

  def handle_cast({:attempt_command, %DepositMoney{} = command, %EventMetadata{} = meta}, state) do
    event = %{%MoneyDeposited{} | id: command.id, amount: command.amount,
              transaction_date: DateTime.utc_now, guid: meta.event_id}
    case write_event(event, state, @stream_should_exist) do
      {:error, reason, protomsg} ->
        # This should only happen if someone tries to Deposit on a stream that doesn't exist.
        Logger.error("Error occurred: #{reason} - #{inspect protomsg}")
        retry_command(command, meta)
      {:ok, _response} ->
        # TODO: Answer this question:
        # Should I create some sort of LoadTransaction record like we do for cards?
        :ok
    end
    {:noreply, state}
  end

  def handle_cast({:attempt_command, %WithdrawMoney{} = command, %EventMetadata{} = meta}, state) do
    new_balance = state.balance - command.amount
    event = case new_balance < 0 do
      true ->
        %WithdrawDeclined{id: command.id, amount: command.amount,
                          transaction_date: DateTime.utc_now, guid: meta.event_id}
      false ->
        %MoneyWithdrawn{id: command.id, amount: command.amount,
                        transaction_date: DateTime.utc_now, guid: meta.event_id}
    end

    case write_event(event, state, state.last_event) do
      {:error, _, _} ->
        retry_command(command, meta)
      {:ok, _response} ->
        :ok
    end

    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, %{subscription_ref: ref} = state) do
    GenServer.cast self, :subscribe
    {:noreply, %{state|subscription_ref: nil}}
  end

  def handle_info({:on_event, push}, state) do
    data = :erlang.binary_to_term(push.event.data)
    case push.event.event_type do
      "Elixir.Events.MoneyDeposited" ->
        update_params = %{balance: state.balance + data.amount, last_event_processed: state.last_event + 1}
        wallet = Repo.get!(Wallet, state.id) |> Wallet.update_changeset(update_params) |> Repo.update!
        {:noreply, %{state | balance: wallet.balance, last_event: wallet.last_event_processed}}
      "Elixir.Events.MoneyWithdrawn" ->
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

  ##################
  #     Utility    #
  ##################

  defp write_event(event, state, expected_version \\ -2) do
    Extreme.execute(state.event_store, Utilities.write_events(state.stream, [event], expected_version))
  end

  defp via_tuple(wallet) do
    {:via, :gproc, {:n, :l, {:wallet, wallet}}}
  end

  defp retry_command(command, meta) do
    GenServer.cast(self, {:attempt_command, command, %{meta | retries: meta.retries - 1}})
  end
end
