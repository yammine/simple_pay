defmodule SimplePay.EventProcessor do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, nil}
  end

  # TODO: Handle all the events
end
