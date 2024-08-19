defmodule StrLen.CompareTest do
  use ExUnit.Case
  import StrLen.Sigils
  alias StrLen.Compare

  test "compare" do
    assert Compare.compare(~SR[5:5], ~SR[11:5]) == :disjoint
    assert Compare.compare(~SR[5:5], ~SR[6:3]) == :covers
    assert Compare.compare(~SR[5:5], ~SR[3:10]) == :covered_by
    assert Compare.compare(~SR[5:5], ~SR[8:10]) == :overlaps_start
    assert Compare.compare(~SR[5:5], ~SR[3:5]) == :overlaps_end
    assert Compare.compare(~SR[5:5], ~SR[5:5]) == :equal
  end
end
