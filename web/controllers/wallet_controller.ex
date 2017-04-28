defmodule SimplePay.WalletController do
  use SimplePay.Web, :controller
  import Ecto.Query

  alias SimplePay.{Wallet}
  alias Commands.{DepositMoney}
  alias SimplePay.Wallet.CommandHandler

  def show(conn, _) do
    user = Guardian.Plug.current_resource(conn)
    wallet = from(w in Wallet, where: w.user_id == ^user.id, limit: 1, preload: [:user])
      |> Repo.one
    changeset = Wallet.empty_changeset(wallet)
    render(conn, "show.html", wallet: wallet, changeset: changeset)
  end

  def deposit(conn, %{"wallet" => %{"amount" => amount}}) do
    user = Guardian.Plug.current_resource(conn)
    wallet = from(w in Wallet, where: w.user_id == ^user.id, limit: 1, preload: [:user])
      |> Repo.one

    int_amount = case Integer.parse(amount) do
      {amt, _} -> amt
      :error -> 0
    end

    case CommandHandler.attempt_command(%DepositMoney{id: wallet.id, amount: int_amount}) do
      :ok ->
        conn
        |> put_flash(:info, "We have received your deposit and are now processing.")
        |> redirect(to: wallet_path(conn, :show))
      {:error, message} ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: wallet_path(conn, :show))
    end
  end
end
