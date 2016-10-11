# A virtual model -- nothing gets persisted here
defmodule SimplePay.Session do
  use SimplePay.Web, :model

  alias Comeonin.Bcrypt
  alias SimplePay.{User, Repo}

  schema "sessions" do
    field :email, :string, virtual: true
    field :password, :string, virtual: true
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:email, :password])
  end

  def find_user_and_confirm_password(struct, params \\ %{}) do
    struct
    |> cast(params, [:email, :password])
    |> validate_required([:email, :password])
    |> confirm_credentials
  end

  defp confirm_credentials(%Ecto.Changeset{valid?: false} = changeset), do: {:error, changeset}
  defp confirm_credentials(%Ecto.Changeset{valid?: true, changes: %{email: email, password: password}} = changeset) do
    with user    <- Repo.get_by(User, email: email),
         true    <- check_password(user, password) do
      {:ok, user}
    else
      _ -> {:error, add_error(changeset, :login, "Email or password is incorrect.")} # Error message not used at the moment
    end
  end

  defp check_password(nil, _password), do: Bcrypt.dummy_checkpw
  defp check_password(%User{password_hash: stored_password}, password) do
    Bcrypt.checkpw(password, stored_password)
  end
end
