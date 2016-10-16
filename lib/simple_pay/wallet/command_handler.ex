defmodule SimplePay.Wallet.CommandHandler do
  alias SimplePay.Wallet.{Supervisor, Aggregate}
  alias Commands.{CreateWallet, DepositMoney, WithdrawMoney}
  require Logger

  def attempt_command(command) do
    command
    |> validate
    |> find_wallet
    |> command
  end

  defp validate(command) do
    Logger.info("Validating Command: #{inspect command}")
    case command do
      %DepositMoney{} = cmd ->
        cmd |> verify_valid_amount
      %WithdrawMoney{} = cmd ->
        cmd |> verify_valid_amount
      _ ->
        {:ok, command}
    end
  end

  defp verify_valid_amount(command) do
    if command.amount > 0 and is_integer(command.amount) do
      {:ok, command}
    else
      {:error, "Invalid value for 'amount'"}
    end
  end

  defp find_wallet({:error, _message} = error_tuple), do: error_tuple
  defp find_wallet({:ok, command}) do
    case :gproc.where(gproc_key(command.id)) do
      :undefined ->
        {:ok, pid} = Supervisor.add_child(command.id)
        {pid, command}
      pid when is_pid(pid) ->
        {pid, command}
    end
  end

  defp gproc_key(wallet_id) do
    {:n, :l, {:wallet, wallet_id}}
  end

  defp command({:error, message}), do: {:error, message}
  defp command({pid, command}) do
    :ok = Aggregate.apply(pid, command)
  end

end
