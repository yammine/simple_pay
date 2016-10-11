defmodule SimplePay.PageController do
  use SimplePay.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def protected_route(conn, _) do
    render conn, "protected_route.html"
  end
end
