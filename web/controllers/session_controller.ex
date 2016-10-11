defmodule SimplePay.SessionController do
  use SimplePay.Web, :controller

  alias SimplePay.Session

  def new(conn, _params) do
    changeset = Session.changeset(%Session{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"session" => session_params}) do
    case Session.find_user_and_confirm_password(%Session{}, session_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Logged in successfully.")
        |> Guardian.Plug.sign_in(user)
        |> redirect(to: "/")
      {:error, changeset} ->
        render(conn, "new.html", changeset: %{changeset|action: :insert})
    end
  end

  def delete(conn, _) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> Guardian.Plug.sign_out
    |> redirect(to: "/")
  end
end
