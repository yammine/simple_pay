defmodule SimplePay.WalletTest do
  use SimplePay.ModelCase

  alias SimplePay.Wallet

  @valid_attrs %{}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Wallet.changeset(%Wallet{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Wallet.changeset(%Wallet{}, @invalid_attrs)
    refute changeset.valid?
  end
end
