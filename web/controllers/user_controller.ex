defmodule SimplePay.UserController do
  use SimplePay.Web, :controller

  alias SimplePay.{User, Wallet}
  alias SimplePay.Wallet.CommandHandler
  alias Commands.CreateWallet

  def index(conn, _params) do
    users = Repo.all(User)
    render(conn, "index.html", users: users)
  end

  def new(conn, _params) do
    changeset = User.changeset(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    changeset = User.changeset(%User{}, user_params)

    with {:ok, user} <- Repo.insert(changeset),
         {:ok, wallet} <- Repo.insert(Wallet.changeset(%Wallet{}, user)),
         :ok <- CommandHandler.attempt_command(%CreateWallet{id: wallet.id}) do
      conn
      |> put_flash(:info, "Signed up successfully.")
      |> redirect(to: session_path(conn, :new))
    else
      {:error, %Ecto.Changeset{data: %User{}} = changeset} ->
        render(conn, "new.html", changeset: changeset)
      _ ->
        raise("Internal server error.")
    end
  end

  def show(conn, %{"id" => id}) do
    user = Repo.get!(User, id)
    render(conn, "show.html", user: user)
  end

  def show(conn, _) do
    user = Guardian.Plug.current_resource(conn)
    render(conn, "account.html", user: user)
  end

  def edit(conn, _) do
    user = Guardian.Plug.current_resource(conn)
    changeset = User.update_changeset(user)
    render(conn, "edit.html", user: user, changeset: changeset)
  end

  def update(conn, %{"user" => user_params}) do
    user = Guardian.Plug.current_resource(conn)
    changeset = User.update_changeset(user, user_params)

    case Repo.update(changeset) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Account updated successfully.")
        |> redirect(to: account_path(conn, :show))
      {:error, changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset)
    end
  end

  def delete(conn, _) do
    user = Guardian.Plug.current_resource(conn)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(user)

    conn
    |> put_flash(:info, "Account destroyed.")
    |> Guardian.Plug.sign_out
    |> redirect(to: "/")
  end
end
