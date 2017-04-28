defmodule SimplePay.Wallet do
  use SimplePay.Web, :model

  alias SimplePay.User

  schema "wallets" do
    belongs_to :user, SimplePay.User
    field :last_event_processed, :integer
    # It is important to use this only as a snapshot value,
    # the real balance of any wallet is whatever the Wallet Aggregate(for wallet with this id) says it is
    field :balance, :integer # Smallest denomination of any currency (i.e. cents for CAD)

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def empty_changeset(struct), do: struct |> change
  def changeset(struct, %User{} = user) do
    struct
    |> change
    |> put_assoc(:user, user)
  end

  def update_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:balance, :last_event_processed])
  end
end
