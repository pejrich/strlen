defmodule StrLen.StringRange do
  @moduledoc """
  StringRange represents a range in a string, preserving lengths for different counting methods.
  This string: "👨‍👩‍👧‍👦👨‍👩‍👧‍👦", is 50 bytes long.
  iex> byte_size("👨‍👩‍👧‍👦👨‍👩‍👧‍👦")
  50
  It's 14 codepoints long.
  iex> String.codepoints("👨‍👩‍👧‍👦👨‍👩‍👧‍👦") |> length()
  14
  iex> to_charlist("👨‍👩‍👧‍👦👨‍👩‍👧‍👦") |> length()
  14
  It's 2 characters long.
  iex> String.length("👨‍👩‍👧‍👦👨‍👩‍👧‍👦")
  2

  These are what `byte`, `code`, and `char` represent. So what is `utf16`? This is used by
  Javscript, NSString on Apple, and maybe others.
  First we convert UTF8 to UTF16
  iex> utf16_bytes = :unicode.characters_to_binary("👨‍👩‍👧‍👦👨‍👩‍👧‍👦", :utf8, :utf16)
  <<216, 61, 220, 104, ...>>
  iex> byte_size(utf16_bytes)
  44
  So it's 44 bytes long, but since utf16 is a 16 bit encoding, rather than 8, it's 22 units long

  So if we take the string "👨‍👩‍👧‍👦family👨‍👩‍👧‍👦". The range of the second emoji, is:
  StrLen.StringRange.new([byte: {31, 25}, char: {7, 1}, code: {13, 7}, utf16: {17, 11}])

  You'll have to use the correct range when you're actually slicing a string. If you're not sure which one to use for your given platform/language, get the length of this string `"👨‍👩‍👧‍👦"`.
  If it's 1, use `:char`
  If it's 7, use `:code`
  If it's 11, use `:utf16`
  If it's 25, use `:byte`
  """
  @derive Jason.Encoder
  defstruct [:byte, :char, :code, :utf16]

  @type t :: %__MODULE__{
          byte: SLRange.t(),
          char: SLRange.t(),
          code: SLRange.t(),
          utf16: SLRange.t()
        }

  @zero %{
    Macro.struct!(__MODULE__, __ENV__)
    | byte: SLRange.new(0, 0),
      char: SLRange.new(0, 0),
      code: SLRange.new(0, 0),
      utf16: SLRange.new(0, 0)
  }
  def zero, do: @zero

  def new(%__MODULE__{} = r), do: r

  def new(%{"byte" => byte, "char" => char, "code" => code, "utf16" => utf16}),
    do: %__MODULE__{
      byte: SLRange.new(byte),
      char: SLRange.new(char),
      code: SLRange.new(code),
      utf16: SLRange.new(utf16)
    }

  def new(%{byte: byte, char: char, code: code, utf16: utf16}),
    do: %__MODULE__{
      byte: SLRange.new(byte),
      char: SLRange.new(char),
      code: SLRange.new(code),
      utf16: SLRange.new(utf16)
    }

  def new(byte: {v1, v2}, char: {v3, v4}, code: {v5, v6}, utf16: {v7, v8}) do
    %__MODULE__{
      byte: SLRange.new(v1, v2),
      char: SLRange.new(v3, v4),
      code: SLRange.new(v5, v6),
      utf16: SLRange.new(v7, v8)
    }
  end

  def new({_, _} = r), do: new(byte: r, char: r, code: r, utf16: r)

  def new(string, last \\ @zero, offset \\ 0)
  def new("" <> string, nil, offset), do: new(string, @zero, offset)

  def new("" <> string, %__MODULE__{} = last, offset) do
    len = StrLen.Length.new(string)

    %__MODULE__{
      byte: SLRange.new(last.byte.stop + 1 + offset, len.byte),
      char: SLRange.new(last.char.stop + 1 + offset, len.char),
      code: SLRange.new(last.code.stop + 1 + offset, len.code),
      utf16: SLRange.new(last.utf16.stop + 1 + offset, len.utf16)
    }
  end

  def add(%__MODULE__{} = left, "" <> binary), do: add(left, StrLen.Length.new(binary))

  def add(%__MODULE__{} = left, %StrLen.Length{} = right) do
    %__MODULE__{
      byte: SLRange.extend(left.byte, right.byte),
      char: SLRange.extend(left.char, right.char),
      code: SLRange.extend(left.code, right.code),
      utf16: SLRange.extend(left.utf16, right.utf16)
    }
  end

  @spec slice(String.t(), __MODULE__.t()) :: String.t()
  @doc """
  Extracts a range from a string. Similar to `String.slice/3` or `:binary.part/3`
  """
  def slice("" <> string, %__MODULE__{byte: range}),
    do: :binary.part(string, range.start, range.length)

  @spec shift_to_zero(__MODULE__.t()) :: __MODULE__.t()
  @doc """
  Adjust the range as if it was the start of a string.
  iex> StrLen.StringRange.new([byte: {31, 25}, char: {7, 1}, code: {13, 7}, utf16: {17, 11}])
  ...> |> StrLen.StringRange.shift_to_zero()
  StrLen.StringRange.new([byte: {0, 25}, char: {0, 1}, code: {0, 7}, utf16: {0, 11}])
  """
  def shift_to_zero(%__MODULE__{byte: byte, char: char, code: code, utf16: utf16}) do
    %__MODULE__{
      byte: SLRange.new(0, byte.length),
      char: SLRange.new(0, char.length),
      code: SLRange.new(0, code.length),
      utf16: SLRange.new(0, utf16.length)
    }
  end

  # def shift_start(left, right, sign \\ 1)

  # @spec shift_start(__MODULE__.t(), StrLen.Length.t()) :: __MODULE__.t()
  @doc """
  Moves the start of the range based on a another strings length.
  For example if you preprended a string.

  iex> range = StrLen.StringRange.new([byte: {0, 25}, char: {0, 1}, code: {0, 7}, utf16: {0, 11}])
  iex> length = StrLen.Length.new("👨‍👩‍👧‍👦")
  iex> StrLen.StringRange.shift_start(range, length)
  StrLen.StringRange.new([byte: {25, 25}, char: {1, 1}, code: {7, 7}, utf16: {11, 11}])

  The range changed from the first emoji in "👨‍👩‍👧‍👦",
  to the second emoji in "👨‍👩‍👧‍👦👨‍👩‍👧‍👦"
  """

  # def shift_start(
  #       %__MODULE__{byte: byte, char: char, code: code, utf16: utf16} = a,
  #       %StrLen.Length{} = length,
  #       sign
  #     ) do
  #       shift()
  #   # %__MODULE__{
  #   #   byte: SLRange.shift_start(byte, length.byte * sign),
  #   #   char: SLRange.shift_start(char, length.char * sign),
  #   #   code: SLRange.shift_start(code, length.code * sign),
  #   #   utf16: SLRange.shift_start(utf16, length.utf16 * sign)
  #   # }
  # end

  def shift_start(%__MODULE__{} = left, %__MODULE__{} = right),
    do: shift(left, following: right)

  @doc """
  This extends a range as if it stopped at it's current stop position, but started at zero.
        |----|       =>  |----------|
  __________________ =>  __________________
  """
  def extend_to_zero(%__MODULE__{byte: byte, char: char, code: code, utf16: utf16}) do
    %__MODULE__{
      byte: SLRange.new(start: 0, stop: byte.stop),
      char: SLRange.new(start: 0, stop: char.stop),
      code: SLRange.new(start: 0, stop: code.stop),
      utf16: SLRange.new(start: 0, stop: utf16.stop)
    }
  end

  @spec shift(__MODULE__.t(), [{:following, __MODULE__.t()}]) :: __MODULE__.t()
  @doc """
  This function shifts the first argument such that it comes immediately after the second arguement

  iex> shift(%StrRng{byte: {10, 5}, char: {5, 1}}, following: %StrRng{byte: {20, 10}, char: {15, 5}})
  %StrRng{byte: {30, 5}, char: {20, 1}}
  """
  def shift(%__MODULE__{} = str_rng, following: %__MODULE__{} = prev) do
    %__MODULE__{
      byte: SLRange.new(start: prev.byte.stop + 1, length: str_rng.byte.length),
      char: SLRange.new(start: prev.char.stop + 1, length: str_rng.char.length),
      code: SLRange.new(start: prev.code.stop + 1, length: str_rng.code.length),
      utf16: SLRange.new(start: prev.utf16.stop + 1, length: str_rng.utf16.length)
    }
  end

  @spec combine([__MODULE__.t()]) :: __MODULE__.t()
  @doc """
  Combines or colapses multiple ranges into a single range.
  It will first sort the ranges, so they don't need to be in order, but it does assume the 2 ranges with the largest and smallest start, constitute the entire bounds of the range.
  """
  def combine([ranges]), do: ranges

  def combine([_, _ | _] = list) do
    [h | t] = Enum.sort_by(list, & &1.byte.start)
    l = List.last(t)

    %__MODULE__{
      byte: SLRange.new(start: h.byte.start, stop: l.byte.stop),
      char: SLRange.new(start: h.char.start, stop: l.char.stop),
      code: SLRange.new(start: h.code.start, stop: l.code.stop),
      utf16: SLRange.new(start: h.utf16.start, stop: l.utf16.stop)
    }
  end

  @spec compare(__MODULE__.t(), __MODULE__.t()) :: :eq | :lt | :gt
  @doc """
  WARNING: Ranges don't sort as simply as integers. For example is the range 1..4 larger or smaller than the range 2..3? It starts lower, but it's also longer.
  This compare function only deals with the starting point of the range, so 1..4 is less than 2..3
  but this is by no means a complete solution, but it works for the use case that you have N ranges of words in a string, that don't overlap, and you want them sorted in order. If you have N overlapping ranges, you will need to use something else.
  """
  def compare(%{byte: %{start: start}}, %{byte: %{start: start}}), do: :eq
  def compare(%{byte: %{start: start}}, %{byte: %{start: start2}}) when start < start2, do: :lt
  def compare(%{byte: %{start: start}}, %{byte: %{start: start2}}) when start > start2, do: :gt

  def compact(%{byte: a, utf16: a, code: a, char: a}), do: [a.start, a.length]
  def compact(%{byte: a, utf16: b, code: b, char: b}), do: [a.start, a.length, b.start, b.length]

  def compact(%{byte: a, utf16: b, code: c, char: c}),
    do: [a.start, a.length, b.start, b.length, c.start, c.length]

  def compact(%{byte: a, utf16: b, code: c, char: d}),
    do: [a.start, a.length, b.start, b.length, c.start, c.length, d.start, d.length]

  def expand([a, b]), do: expand([a, b, a, b])
  def expand([a, b, c, d]), do: expand([a, b, c, d, c, d])
  def expand([a, b, c, d, e, f]), do: expand([a, b, c, d, e, f, e, f])

  def expand([a, b, c, d, e, f, g, h]),
    do: new(%{byte: {a, b}, utf16: {c, d}, code: {e, f}, char: {g, h}})

  def from_string(string) do
    with [a, b, c, d] <- String.split(string, "|"),
         byte <- SLRange.new(a),
         utf16 <- SLRange.new(b),
         code <- SLRange.new(c),
         char <- SLRange.new(d) do
      new(%{byte: byte, char: char, code: code, utf16: utf16})
    else
      [_ | _] = list ->
        diff = 4 - length(list)

        (list ++ List.duplicate(List.last(list), diff))
        |> Enum.join("|")
        |> from_string()
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(rng, _opts) do
      concat(["~SR[", to_string(rng), "]"])
    end
  end

  defimpl String.Chars do
    def to_string(%{byte: byte, char: char, code: code, utf16: utf16}) do
      [byte, utf16, code, char] |> Enum.map_join("|", &range_str/1)
    end

    def range_str(%{start: start, length: len}), do: "#{start}:#{len}"
  end
end
