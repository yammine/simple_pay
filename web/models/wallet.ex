defmodule SimplePay.Wallet do
  use SimplePay.Web, :model

  alias SimplePay.User

  schema "wallets" do
    belongs_to :user, SimplePay.User

    field :balance, :float, virtual: true

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, %User{} = user) do
    struct
    |> change
    |> put_assoc(:user, user)
  end
end
