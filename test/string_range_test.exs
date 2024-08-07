defmodule StrLen.StringRangeTest do
  use ExUnit.Case
  import StrLen.Sigils
  alias StrLen.StringRange, as: StrRng
  alias StrLen.Length

  @length Length.new("é")
  @range Length.range_from(@length, "é")
  test "add" do
    assert @range.byte.start == 2
    assert @range.byte.stop == 3
    assert @range.char.start == 1
    assert @range.char.stop == 1
    range = StrRng.add(@range, "é")
    assert range.byte.start == 2
    assert range.byte.stop == 5
    assert range.char.start == 1
    assert range.char.stop == 2
  end

  test "shift_start" do
    rng = Length.new("e") |> StrLen.range_from_point(0)
    range = StrRng.shift(@range, following: rng)
    assert range.byte.start == 1
    assert range.byte.stop == 2
    assert range.char.stop == 1
    range = StrRng.shift(range, following: rng)
    assert range.byte.start == 1
    assert range.byte.stop == 2
    assert range.char.stop == 1
  end

  test "combine" do
    r1 = Length.range_from(Length.new("ábc"), "ábc")
    r2 = Length.range_from(Length.new("ábcabc"), "áb")
    r3 = Length.range_from(Length.new("ábcabcabc"), "á")
    r4 = Length.range_from(Length.new("ábcabcabcabc"), "ábcd")
    assert %{byte: %{start: 4, stop: 17, length: 14}} = StrRng.combine([r1, r2, r3, r4])
    assert %{byte: %{start: 4, stop: 17, length: 14}} = StrRng.combine([r2, r3, r4, r1])
    assert %{byte: %{start: 4, stop: 17, length: 14}} = StrRng.combine([r3, r4, r1, r2])
    assert %{byte: %{start: 4, stop: 17, length: 14}} = StrRng.combine([r4, r1, r2, r3])
  end

  test "shift after" do
    a = ~SR[26:25|12:11|8:7|2:1]
    b = ~SR[0:25|0:11|0:7|0:1]
    c = ~SR[25:25|11:11|7:7|1:1]
    assert c == StrLen.shift(a, after: b)
  end
end
