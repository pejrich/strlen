if Code.ensure_loaded?(Phoenix.HTML.Safe) do
  defimpl Phoenix.HTML.Safe, for: SLRange do
    def to_iodata(%{start: start, stop: stop}), do: "#{start}:#{stop}"
  end
end
