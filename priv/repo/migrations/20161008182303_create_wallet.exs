defmodule SimplePay.Repo.Migrations.CreateWallet do
  use Ecto.Migration

  def change do
    create table(:wallets) do
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end
    create index(:wallets, [:user_id])
  end
end
