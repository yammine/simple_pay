defmodule SimplePay.Wallet.Commands do
  alias SimplePay.Wallet.{Supervisor, Aggregate}
  alias Commands.{CreateWallet, DepositMoney, WithdrawMoney}
  require Logger

  def attempt_command(command) do
    find_wallet(command.id) |> command(command, 5)
  end

  defp command(_, _, 0), do: {:error, "Unexpected error occurred."}

  defp command(pid, %DepositMoney{amount: amount} = command, retries_left) when is_float(amount) do
    case Aggregate.deposit(pid, amount) do
      {:ok, _} ->
        Logger.info("Deposited $#{amount}")
      {:error, _reason, _} ->
        command(pid, command, retries_left-1)
    end
  end

  defp command(pid, %WithdrawMoney{amount: amount} = command, retries_left) when is_float(amount) do
    case Aggregate.withdraw(pid, amount) do
      {:ok, _} ->
        Logger.info("Attempted withdraw")
      {:error, _reason, _} ->
        command(pid, command, retries_left-1)
    end
  end

  defp find_wallet(wallet_id) do
    case :gproc.where(gproc_key(wallet_id)) do
      :undefined ->
        {:ok, pid} = Supervisor.add_child(wallet_id)
        pid
      pid when is_pid(pid) ->
        pid
    end
  end

  defp gproc_key(wallet_id) do
    {:n, :l, {:wallet, wallet_id}}
  end
end
