defmodule SimplePay.Repo.Migrations.CreateWallet do
  use Ecto.Migration

  def change do
    create table(:wallets) do
      add :user_id, references(:users, on_delete: :nothing)
      add :balance, :integer, default: 0
      add :last_event_processed, :integer, default: -1

      timestamps()
    end
    create index(:wallets, [:user_id])
  end
end
