defmodule SLRange do
  @moduledoc """
  This is a slightly more flexible version of Elixir's Range

  You can initialize an SLRange as follows:

  With start/length
  iex> SLRange.new(10, 15)
  SLRange.new(10, 15)
  iex> SLRange.new(start: 10, length: 15)
  SLRange.new(10, 15)

  With start/stop
  iex> SLRange.new(start: 10, stop: 24)
  SLRange.new(10, 15)

  With start/until
  iex> SLRange.new(start: 10, until: 25)
  SLRange.new(10, 15)

  These are all equivalent of this Elixir Range

  iex> 10..24
  10..24

  It conforms to Enumerable

  iex> SLRange.new(10, 15) |> Enum.to_list()
  [10, 11, ..., 23, 24]

  The main reason to use this instead of Elixir's Range is that when working with
  systems that use start/length or start/until(exclusive) semantics, trying to remember
  to get it right each time, and add the 1, or subtract the 1 can lead to bugs

  """
  alias __MODULE__
  defstruct [:start, :length, :stop, step: 1]

  @type t :: %SLRange{
          start: pos_integer(),
          length: pos_integer(),
          stop: pos_integer(),
          step: pos_integer()
        }

  defguard is_valid_range(r) when r.start + r.length - 1 == r.stop

  def to_range(%SLRange{start: start, stop: stop, step: step}), do: start..stop//step

  def parse(<<a, b, c, d>>) when a in ?0..?9 and b in ?0..?9 and c in ?0..?9 and d in ?0..?9,
    do: String.to_integer(<<a, b, c, d>>)..String.to_integer(<<a, b, c, d>>)

  def parse(<<a, b, c>>) when a in ?0..?9 and b in ?0..?9 and c in ?0..?9,
    do: String.to_integer(<<a, b, c>>)..String.to_integer(<<a, b, c>>)

  def parse(<<a, b>>) when a in ?0..?9 and b in ?0..?9,
    do: String.to_integer(<<a, b>>)..String.to_integer(<<a, b>>)

  def parse(<<a>>) when a in ?0..?9, do: String.to_integer(<<a>>)..String.to_integer(<<a>>)

  Enum.each(1..6, fn i ->
    Enum.each(1..6, fn j ->
      match =
        "<<#{Enum.map_join(1..i, ", ", &"vari#{&1}")}, \"..\", #{Enum.map_join(1..j, ", ", &"varj#{&1}")}>> = str"

      guard =
        Enum.map_join(
          Enum.map(1..i, &"vari#{&1}") ++ Enum.map(1..j, &"varj#{&1}"),
          " and ",
          &"#{&1} in ?0..?9"
        )

      def parse(unquote(Code.string_to_quoted!(match)))
          when unquote(Code.string_to_quoted!(guard)) do
        String.split(str, "..")
        |> Enum.map(&String.to_integer/1)
        |> then(fn [a, b] -> new(a..b) end)
      end
    end)
  end)

  def parse(<<a::binary-4, "..", b::binary-4>>),
    do: new(start: String.to_integer(a, 16), stop: String.to_integer(b, 16))

  def parse(<<a::binary-5, "..", b::binary-5>>),
    do: new(start: String.to_integer(a, 16), stop: String.to_integer(b, 16))

  def new(%Range{first: first, last: last, step: step}),
    do: new(start: first, stop: last, step: step)

  def new(%__MODULE__{} = range) when is_valid_range(range), do: range
  def new({start, length}), do: new(start: start, length: length)

  def new(start: start, stop: stop) when is_integer(start) and is_integer(stop),
    do: %SLRange{start: start, length: stop - start + 1, stop: stop}

  def new(start: start, length: length) when is_integer(start) and is_integer(length),
    do: new(start, length)

  def new(start: start, until: until) when is_integer(start) and is_integer(until),
    do: new(start: start, stop: until - 1)

  def new(start: start, stop: stop, step: step)
      when is_integer(start) and is_integer(stop) and is_integer(step) do
    %SLRange{start: start, length: stop - start + 1, stop: stop, step: step}
  end

  def new([start, length]), do: new(start, length)

  def new(start, length) when is_integer(start) and is_integer(length),
    do: %SLRange{start: start, length: length, stop: start + length - 1}

  # The convention here is that `10:15` means `index 10, length 15`, and `10-15` means `from 10 to 15`.
  # So `10:15` == `10-25`
  Enum.each(1..20, fn i ->
    def new(<<a::binary-size(unquote(i)), ":", b::binary>>),
      do: new(start: String.to_integer(a), length: String.to_integer(b))

    def new(<<a::binary-size(unquote(i)), "-", b::binary>>),
      do: new(start: String.to_integer(a), stop: String.to_integer(b))
  end)

  def shift_start(%{start: start, length: length} = range, val) when is_valid_range(range),
    do: new(start + val, length)

  def extend(%{start: start, length: length} = range, val) when is_valid_range(range),
    do: new(start, length + val)

  def similarity(%{start: s1, length: l1} = r, %{start: s2, length: l2} = r2)
      when is_valid_range(r) and is_valid_range(r2),
      do: abs(s1 - s2) + abs(l1 - l2) * 2

  def most_similar(ranges, r1) when is_valid_range(r1) do
    ranges
    |> Stream.with_index()
    |> Enum.reduce_while({nil, nil}, fn {r2, i}, {best, acc} ->
      sim = similarity(r1, r2)
      if sim < best, do: {:cont, {sim, i}}, else: {:halt, acc}
    end)
  end

  def contains?(%{start: start, stop: stop} = r, %{start: start2, stop: stop2} = r2)
      when start2 < start or (stop2 > stop and is_valid_range(r) and is_valid_range(r2)),
      do: false

  def contains?(%{start: start, stop: stop} = r, %{start: start2, stop: stop2} = r2)
      when is_valid_range(r) and is_valid_range(r2) do
    start2 in start..stop && stop2 in start..stop
  end

  @doc """
  Gives the absolute value of the distance from the value to the range edges
  4..5, 5 == distance 0
  1..5, 2 == distance 0
  1..5, 10 == distance 5
  5..10, 0 == distance 5
  """
  def distance(%{start: a, stop: b} = range, value)
      when value >= a and value <= b and is_valid_range(range),
      do: 0

  def distance(%{start: a, stop: b} = range, value) when is_valid_range(range),
    do: Enum.min([abs(a - value), abs(b - value)])

  @doc """
  returns the amount of matching between two ranges.
  Identical ranges get a score of 0.
  10:20, 10:20 -> 0
  10:20, 10:18 -> -2
  10:20, 10:22 -> 2
  10:20, 25:30 -> nil
  """
  def match(%{start: st, stop: sp} = r, %{start: st, stop: sp} = r2)
      when is_valid_range(r) and is_valid_range(r2),
      do: 0

  def match(%{start: st, stop: sp} = r, %{start: st, stop: sp} = r2)
      when is_valid_range(r) and is_valid_range(r2),
      do: 0

  def match(%{start: st, stop: sp1} = r, %{start: st, stop: sp2} = r2)
      when is_valid_range(r) and is_valid_range(r2),
      do: sp2 - sp1

  def match(%{start: st1, stop: sp} = r, %{start: st2, stop: sp} = r2)
      when is_valid_range(r) and is_valid_range(r2),
      do: st1 - st2

  def match(%{start: st1, stop: sp1} = r, %{start: st2, stop: sp2} = r2)
      when (is_valid_range(r) and is_valid_range(r2) and st2 > sp1) or sp2 < st1,
      do: nil

  def match(%{start: st1, stop: sp1} = r, %{start: st2, stop: sp2} = r2)
      when is_valid_range(r) and is_valid_range(r2) do
    st_max = max(st1, st2)
    sp_min = min(sp1, sp2)
    sp2 - st2 - (sp_min - st_max)
  end

  def redistribute(array, %{start: old_min, stop: old_max}, %{start: new_min, stop: new_max}) do
    Enum.map(array, &((&1 - old_min) * (new_max - new_min) / (old_max - old_min) + new_min))
  end

  def redistribute(array, new_range) do
    {min, max} = Enum.min_max(array)
    redistribute(array, %{start: min, stop: max}, new_range)
  end

  if Code.ensure_loaded?(Ecto.Type) do
    ########################################################################
    ### Ecto.Type
    ########################################################################
    use Ecto.Type

    @impl true
    def type, do: SLRange

    @impl true
    def cast(%SLRange{} = range) when is_valid_range(range), do: {:ok, range}
    def cast(%{start: start, length: length}), do: {:ok, SLRange.new(start, length)}
    def cast([start, length]), do: {:ok, SLRange.new(start, length)}

    @impl true
    def load([start, length]),
      do: {:ok, SLRange.new(start, length)}

    @impl true
    def dump(%SLRange{start: s, length: l} = r) when is_valid_range(r), do: [s, l]
    def dump(_), do: :error
  end
end

defimpl Enumerable, for: SLRange do
  import SLRange

  def reduce(a, b, c) when is_valid_range(a) do
    SLRange.to_range(a)
    |> Enumerable.reduce(b, c)
  end

  def count(a), do: SLRange.to_range(a) |> Enumerable.count()
  def member?(a, b), do: SLRange.to_range(a) |> Enumerable.member?(b)
  def slice(a), do: SLRange.to_range(a) |> Enumerable.slice()
end

defimpl Inspect, for: SLRange do
  import Inspect.Algebra
  import SLRange

  def inspect(%{start: s, length: l} = r, opts) when is_valid_range(r) do
    concat(["SLRange.new(", to_doc(s, opts), ", ", to_doc(l, opts), ")"])
  end
end

defimpl Jason.Encoder, for: SLRange do
  import SLRange

  def encode(%{start: a, length: b} = r, opts) when is_valid_range(r),
    do: Jason.Encode.list([a, b], opts)
end

defimpl String.Chars, for: SLRange do
  import SLRange
  def to_string(%{start: start, length: len} = r) when is_valid_range(r), do: "{#{start}, #{len}}"
end

defimpl Jason.Encoder, for: Range do
  def encode(%{first: f, last: l}, opts), do: Jason.Encode.list([f, l], opts)
end
