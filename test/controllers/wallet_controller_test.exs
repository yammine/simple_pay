defmodule SimplePay.WalletControllerTest do
  use SimplePay.ConnCase

  alias SimplePay.Wallet
  @valid_attrs %{}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, wallet_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing wallets"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, wallet_path(conn, :new)
    assert html_response(conn, 200) =~ "New wallet"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, wallet_path(conn, :create), wallet: @valid_attrs
    assert redirected_to(conn) == wallet_path(conn, :index)
    assert Repo.get_by(Wallet, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, wallet_path(conn, :create), wallet: @invalid_attrs
    assert html_response(conn, 200) =~ "New wallet"
  end

  test "shows chosen resource", %{conn: conn} do
    wallet = Repo.insert! %Wallet{}
    conn = get conn, wallet_path(conn, :show, wallet)
    assert html_response(conn, 200) =~ "Show wallet"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, wallet_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    wallet = Repo.insert! %Wallet{}
    conn = get conn, wallet_path(conn, :edit, wallet)
    assert html_response(conn, 200) =~ "Edit wallet"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    wallet = Repo.insert! %Wallet{}
    conn = put conn, wallet_path(conn, :update, wallet), wallet: @valid_attrs
    assert redirected_to(conn) == wallet_path(conn, :show, wallet)
    assert Repo.get_by(Wallet, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    wallet = Repo.insert! %Wallet{}
    conn = put conn, wallet_path(conn, :update, wallet), wallet: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit wallet"
  end

  test "deletes chosen resource", %{conn: conn} do
    wallet = Repo.insert! %Wallet{}
    conn = delete conn, wallet_path(conn, :delete, wallet)
    assert redirected_to(conn) == wallet_path(conn, :index)
    refute Repo.get(Wallet, wallet.id)
  end
end
