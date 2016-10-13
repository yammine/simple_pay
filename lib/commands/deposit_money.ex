defmodule Commands.DepositMoney do
  defstruct [:id, :amount]

  @type t :: %__MODULE__{}
end
