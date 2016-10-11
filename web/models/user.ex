defmodule SimplePay.User do
  use SimplePay.Web, :model
  alias Comeonin.Bcrypt

  schema "users" do
    field :email, :string
    field :password_hash, :string

    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true


    field :new_password, :string, virtual: true
    field :new_password_confirmation, :string, virtual: true

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`. This is used for creating a User.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:email, :password, :password_confirmation])
    |> validate_required([:email, :password, :password_confirmation])
    |> unique_constraint(:email)
    |> validate_format(:email, ~r/.*@.*\..{2,}/i)
    |> validate_confirmation(:password)
    |> hash_password
  end

  @doc """
  Used for updating an existing User.
  """
  def update_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:email, :password, :new_password, :new_password_confirmation])
    |> validate_required([:password])
    |> validate_correct_password
    |> delete_change(:password) # After checking the validity of this we no longer want it in our changeset
    |> check_which_updates
  end

  # We attempt to see which constraints/validations we should apply to our Changeset by looking at any
  # queued up changes.
  defp check_which_updates(%Ecto.Changeset{valid?: false} = changeset), do: changeset
  defp check_which_updates(%Ecto.Changeset{valid?: true} = changeset) do
    change_functions = for {change_key, _change_value} <- changeset.changes do
      case change_key do
        :email ->
          [
            &(unique_constraint(&1, :email)),
            &(validate_format(&1, :email, ~r/.*@.*\..{2,}/i))
          ]
        :new_password ->
          [
            &(validate_required(&1, [:new_password_confirmation])),
            &(validate_confirmation(&1, :new_password)),
            &(hash_password(&1))
          ]
        _ -> []
      end
    end |> List.flatten

    changeset |> apply_dynamic_validations(change_functions)
  end

  # Accepts an %Ecto.Changeset{} and a list of anonymous functions to execute with the changeset as their first argument
  defp apply_dynamic_validations(changeset, []), do: changeset
  defp apply_dynamic_validations(changeset, [next_fun|rest]) do
    apply_dynamic_validations(next_fun.(changeset), rest)
  end

  defp validate_correct_password(%Ecto.Changeset{valid?: false} = changeset), do: changeset
  defp validate_correct_password(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    case Bcrypt.checkpw(password, changeset.data.password_hash) do
      true  -> changeset
      false -> add_error(changeset, :password, "is incorrect.")
    end
  end

  defp hash_password(%Ecto.Changeset{valid?: false} = changeset), do: changeset
  defp hash_password(%Ecto.Changeset{valid?: true, changes: %{new_password: new_password}} = changeset), do: changeset |> change(password_hash: Bcrypt.hashpwsalt(new_password))
  defp hash_password(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset), do: changeset |> change(password_hash: Bcrypt.hashpwsalt(password))
end
