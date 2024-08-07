defmodule StrLen.Length do
  @moduledoc """
  This module handles string counting for all aspects.
  for the string `"👨‍👩‍👧‍👧"`:
  `byte_size`: 25
  `StrLen.codepoint_length`: 7
  `String.length`: 1
  `StrLen.UTF.utf16_byte_size`: 11

  This module lets you do:
  ```
  iex> StrLen.Length.new("👨‍👩‍👧‍👧") |> StrLen.Length.add("👨‍👩‍👧‍👧")
  %StrLen.Length{byte: 50, code: 14, char: 2, utf16: 22}
  ```

  This can be used to offset `StrLen.StringRange.t()`
  """
  defstruct byte: 0, utf16: 0, code: 0, char: 0

  @type t :: %__MODULE__{
          byte: pos_integer(),
          char: pos_integer(),
          code: pos_integer(),
          utf16: pos_integer()
        }

  def zero, do: %__MODULE__{}

  def new(binary \\ 0)
  def new(nil), do: nil
  def new(%__MODULE__{} = length), do: length
  def new(int) when is_integer(int), do: %__MODULE__{byte: int, char: int, code: int, utf16: int}

  def new(%StrLen.StringRange{} = r) do
    %__MODULE__{
      byte: r.byte.length,
      char: r.char.length,
      code: r.code.length,
      utf16: r.utf16.length
    }
  end

  def new("" <> binary), do: StrLen.Native.length(binary)

  def add(%__MODULE__{} = left, "" <> binary), do: add(left, new(binary))

  def add(%__MODULE__{} = left, %__MODULE__{} = right) do
    %__MODULE__{
      byte: left.byte + right.byte,
      char: left.char + right.char,
      code: left.code + right.code,
      utf16: left.utf16 + right.utf16
    }
  end

  @doc """
    Converts a range into a length by taking the length portion of the range
  """
  def from_range(%StrLen.StringRange{} = rng) do
    %__MODULE__{
      byte: rng.byte.length,
      char: rng.char.length,
      code: rng.code.length,
      utf16: rng.utf16.length
    }
  end

  @doc """
    Length to Range starting at zero
  """
  def to_range(length), do: range_from(%__MODULE__{}, length)

  @doc """
    Creates a range from the end of lhs Length
  """
  def range_from(left \\ %__MODULE__{}, right)

  def range_from(%__MODULE__{} = left, "" <> binary), do: range_from(left, new(binary))

  def range_from(%__MODULE__{} = left, %__MODULE__{} = right) do
    %StrLen.StringRange{
      byte: SLRange.new(left.byte, right.byte),
      char: SLRange.new(left.char, right.char),
      code: SLRange.new(left.code, right.code),
      utf16: SLRange.new(left.utf16, right.utf16)
    }
  end

  @spec next_range(__MODULE__.t(), String.t() | __MODULE__.t()) ::
          {StrLen.StringRange.t(), __MODULE__.t()}
  @doc """
  creates a range from the left length, for the given string/length.
  Returns the range plus the new length that covers up to the end of the new range.

  length = StrLen.Length.new("1")
  next_range(length, "two")
  {%StringRange{byte: {1, 3}, ...}, %Length{byte: 4, ...}}
  """
  def next_range(%__MODULE__{} = left, "" <> binary), do: next_range(left, new(binary))

  def next_range(%__MODULE__{} = left, %__MODULE__{} = right) do
    {range_from(left, right), add(left, right)}
  end
end
