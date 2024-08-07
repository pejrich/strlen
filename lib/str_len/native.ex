defmodule StrLen.Native do
  use Rustler, otp_app: :str_len, crate: :strlen

  import Kernel, except: [length: 1]

  def ranges(_strings, _range), do: :erlang.nif_error(:nif_not_loaded)
  def range_from_range(_length, _range), do: :erlang.nif_error(:nif_not_loaded)
  def range_from_point(_length, _int), do: :erlang.nif_error(:nif_not_loaded)
  def length(_string), do: :erlang.nif_error(:nif_not_loaded)
  def replace(_range, _string), do: :erlang.nif_error(:nif_not_loaded)
  def shift_after(_range, _range2), do: :erlang.nif_error(:nif_not_loaded)
end
