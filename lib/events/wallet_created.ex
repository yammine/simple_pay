defmodule Events.WalletCreated do
  defstruct [:id, :date_created]

  @type t :: %__MODULE__{}
end
