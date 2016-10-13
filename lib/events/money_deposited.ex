defmodule Events.MoneyDeposited do
  defstruct [:id, :amount, :transaction_date]

  @type t :: %__MODULE__{}
end
