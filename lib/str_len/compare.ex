defmodule StrLen.Compare do
  def compare(%{byte: a}, %{byte: b}), do: compare(a, b)

  def compare(%{start: s1, stop: e1}, %{start: s2, stop: e2}) do
    cond do
      s1 == s2 and e1 == e2 -> :equal
      s1 <= s2 and e1 >= e2 -> :covers
      s1 >= s2 and s1 <= e2 and e1 <= e2 -> :covered_by
      s2 <= s1 and e2 >= s1 and e2 <= e1 -> :overlaps_end
      s2 <= e1 and s2 >= s1 and e2 >= e1 -> :overlaps_start
      true -> :disjoint
    end
  end
end
