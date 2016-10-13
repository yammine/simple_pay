defmodule Commands.WithdrawMoney do
  defstruct [:id, :amount]

  @type t :: %__MODULE__{}
end
