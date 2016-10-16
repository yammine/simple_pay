defmodule Events.WalletCreated do
  defstruct [:id, :date_created, :guid]

  @type t :: %__MODULE__{}
end
