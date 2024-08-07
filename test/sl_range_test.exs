defmodule SLRangeTest do
  use ExUnit.Case

  test "start/stop/length" do
    r = SLRange.new(50, 5)
    assert r.start == 50
    assert r.length == 5
    assert r.stop == 54
    assert 50..54 == SLRange.to_range(r)
    r2 = SLRange.new(start: 50, stop: 54)
    assert r2 == r
  end

  test "extend" do
    range = SLRange.new(10, 5)
    range = SLRange.extend(range, 5)
    assert range.stop == 19
    assert range.length == 10
  end

  test "shift_start" do
    range = SLRange.new(10, 5)
    range = SLRange.shift_start(range, 5)
    assert range.start == 15
    assert range.stop == 19
    assert range.length == 5
  end

  test "contains?" do
    range = SLRange.new(10, 5)
    assert SLRange.contains?(range, range)
    assert SLRange.contains?(range, SLRange.new(11, 3))
    refute SLRange.contains?(range, SLRange.new(20, 4))
    refute SLRange.contains?(range, SLRange.new(9, 7))
  end
end
