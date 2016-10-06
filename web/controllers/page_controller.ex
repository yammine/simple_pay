defmodule SimplePay.PageController do
  use SimplePay.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
