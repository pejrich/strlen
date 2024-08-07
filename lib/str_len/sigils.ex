defmodule StrLen.Sigils do
  def sigil_SR(string, []) do
    StrLen.StringRange.from_string(string)
  end
end
