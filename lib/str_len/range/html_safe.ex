if Code.ensure_loaded?(Phoenix.HTML.Safe) and not Phoenix.HTML.Safe.impl_for(SLRange.new(0, 0)) do
  defimpl Phoenix.HTML.Safe, for: SLRange do
    def to_iodata(%{start: start, stop: stop}), do: "#{start}:#{stop}"
  end
end
