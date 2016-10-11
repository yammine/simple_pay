defmodule SimplePay.WalletController do
  use SimplePay.Web, :controller
  import Ecto.Query

  alias SimplePay.{Wallet}

  def show(conn, _) do
    user = Guardian.Plug.current_resource(conn)
    wallet = from(w in Wallet, where: w.user_id == ^user.id, limit: 1, preload: [:user])
      |> Repo.one
    render(conn, "show.html", wallet: wallet)
  end
end
