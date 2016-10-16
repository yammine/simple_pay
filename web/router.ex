defmodule SimplePay.Router do
  use SimplePay.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    # Load the user if they are logged in
    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.LoadResource
  end

  pipeline :protected do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    # Verify session & stuff here
    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.EnsureAuthenticated
    plug Guardian.Plug.LoadResource
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SimplePay do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index

    get "/signup", UserController, :new
    resources "/signup", UserController, only: [:create]

    get "/login", SessionController, :new
    resources "/login", SessionController, only: [:create]
  end

  scope "/", SimplePay do
    pipe_through :protected

    get "/protected_route", PageController, :protected_route

    resources "/users", UserController, only: [:show]
    resources "/account", UserController, only: [:show, :edit, :update, :delete], singleton: true, as: :account
    resources "/wallet", WalletController, only: [:show], singleton: true
    post "/wallet/deposit", WalletController, :deposit, as: :deposit

    resources "/sessions", SessionController, only: [:delete], singleton: true
  end

  # Other scopes may use custom stacks.
  # scope "/api", SimplePay do
  #   pipe_through :api
  # end
end
