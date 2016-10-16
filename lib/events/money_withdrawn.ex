defmodule Events.MoneyWithdrawn do
  defstruct [:id, :amount, :transaction_date, :guid]

  @type t :: %__MODULE__{}
end
