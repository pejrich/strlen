defmodule StrLen do
  import Kernel, except: [length: 1]
  alias StrLen.Length, as: Len
  alias StrLen.StringRange, as: Rng

  @moduledoc """
  Have you ever tried to use a string index/range from Elixir in another language? For example JS?

  Maybe it worked for you, but if it did, there's likely a bug in your code.

  "one two"

  The range of "two" here is 4:3(or 4-7), right?
  iex> String.slice("one two", 4, 3)
  "two"
  iex> :binary.part("one two", 4, 3)
  "two"
  js> "one two".slice(4, 7)
  "two"

  So what's the point of this library? Let's change one character.
  "óne two"
  iex> String.slice("óne two", 4, 3)
  "two"
  iex> :binary.part("óne two", 4, 3)
  " tw"
  js> "óne two".slice(4, 7)
  "two"

  Ok, a bit off, but not too bad. Let's change it again, to: "👨‍👩‍👧‍👦ne two"
  iex> String.slice("👨‍👩‍👧‍👦ne two", 4, 3)
  "two"
  iex> :binary.part("👨‍👩‍👧‍👦ne two", 4, 3)
  "\u200D"
  js> "👨‍👩‍👧‍👦ne two".slice(4, 7)
  '/uDC69‍/uD83D'(the / is really a backslash, but elixir tries to parse it as a character)

  So what's going on here?

  The length of this string `"a"`, is 1. To my knowledge on just about every system, that length of that string is 1.

  However this string, `"👨‍👩‍👧‍👦"` has a length of 1, or 7, or 11, or 25.

  It's 1 grapheme cluster(what we colloquially call a "character").
  It's 7 Unicode codepoints(what confusingly is sometimes called a "character").
  It's 11 UTF16 code units(basically it's 22 bytes when encoded at UTF16)
  It's 25 bytes long(assuming a UTF8 encoding which is what Elixir, and many others use).

  Pretty much once you get out of the 127 ASCII characters, you will have one or more of these "lengths" differing. In ASCII you're safe, but in today's world, speakers of every language regularly use characters outside the ASCII range, as Emoji and other Unicode characters are in common use.

  If you're doing everything "in the box", i.e. you're indexing and slicing strings purely within Elixir, then this library will provide no value to you. If however, you're doing some indexing calculations in Elixir, that you need to use in Elixir, and also maybe in a different platform, for example Swift/Objective-C/Java/JavaScript/etc., then this library will help index strings in a way that will work in different platforms, but it comes as a cost of slightly reduced performance and increased complexity.

  If you can get away with sending the presliced strings to the different platforms. e.g. `"👨‍👩‍👧‍👦👨‍👩‍👧‍👦"` becomes `["👨‍👩‍👧‍👦", "👨‍👩‍👧‍👦"]`, then I would advise doing that, as it will keep things simplier, but considering I wrote this library, I'm well aware that sometimes you need to refer to a section of a string(perhaps user input), in a way that it's infeasible to do so in any form other than a integer-based index/range. This library will hopefully help with that.

  The basics are:
  iex> StrLen.length("👨‍👩‍👧‍👦")
  %StrLen.Length{byte: 25, utf16: 11, code: 7, char: 1}
  iex> StrLen.ranges(["👨‍👩‍👧‍👦", "a", "👨‍👩‍👧‍👦"])
  [
  ~StrRng[0:25|0:11|0:7|0:1],
  ~StrRng[25:1|11:1|7:1|1:1],
  ~StrRng[26:25|12:11|8:7|2:1]
  ]
  """

  @spec next_range(String.t() | Len.t(), after: pos_integer() | Len.t() | Rng.t()) :: Rng.t()
  def next_range(val, after: int) when is_integer(int),
    do: next_range(val, after: range_from_point("", int))

  def next_range("" <> string, after: val), do: next_range(length(string), after: val)
  def next_range(val, after: %Len{} = len), do: next_range(val, after: Len.to_range(len))

  def next_range(%Len{} = len, after: %Rng{} = rng), do: range_from_range(len, rng)

  def ranges(strings, range \\ Rng.zero())
  def ranges(strings, range), do: StrLen.Native.ranges(strings, range)
  def range_from_length(val, %Len{} = length), do: range_from_range(val, Len.to_range(length))
  def range_from_range("" <> string, %Rng{} = range), do: range_from_range(length(string), range)

  def range_from_range(%Len{} = len, %Rng{} = range) do
    %Rng{
      byte: SLRange.new(range.byte.stop + 1, len.byte),
      code: SLRange.new(range.code.stop + 1, len.code),
      char: SLRange.new(range.char.stop + 1, len.char),
      utf16: SLRange.new(range.utf16.stop + 1, len.utf16)
    }
  end

  def range_from_point("" <> string, point), do: range_from_point(length(string), point)

  def range_from_point(%Len{} = length, int) when is_integer(int) do
    %Rng{
      byte: SLRange.new(start: int, length: length.byte),
      char: SLRange.new(start: int, length: length.char),
      code: SLRange.new(start: int, length: length.code),
      utf16: SLRange.new(start: int, length: length.utf16)
    }
  end

  def length(string), do: StrLen.Native.length(string)
  @spec replace(Rng.t(), String.t()) :: Rng.t()
  @doc """
  replace/2 takes a range and a string and replaces the range with the given string

  iex> replace(%{byte: {10, 5}, char: {5, 2}, ...}, "here")
  %{byte: {10, 4}, char: {5, 4}, ...}
  """
  def replace(range, string), do: StrLen.Native.replace(range, string)

  def shift(range), do: shift_after(range, Rng.zero())
  def shift(range, after: prev_range), do: shift_after(range, prev_range)
  def shift_after(range, range2), do: StrLen.Native.shift_after(range, range2)

  def merge(%Rng{} = r1, %Rng{} = r2), do: Rng.combine([r1, r2])
  def merge(nil, %Rng{} = r2), do: r2
  def merge(%Rng{} = r1, nil), do: r1

  def slice("" <> string, %Rng{} = range), do: Rng.slice(string, range)

  def add(%Rng{} = rng, val), do: Rng.add(rng, val)
  def add(%Len{} = len, val), do: Len.add(len, val)
end
