defmodule SimplePay.WalletView do
  use SimplePay.Web, :view

  def decorate_currency(number) when is_integer(number), do: (number / 100) |> decorate_currency
  def decorate_currency(float) when is_float(float) do
    [int, decimals] = Float.to_string(float) |> String.split(".")
    case String.length(decimals) do
      1 -> "#{int}.#{decimals}0" # so 0.0 -> 0.00
      _ -> "#{int}.#{decimals}"
    end
  end
end
