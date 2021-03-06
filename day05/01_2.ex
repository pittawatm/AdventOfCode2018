defmodule Logic do
  def match(c1, c2) do
    String.downcase(c1) == String.downcase(c2) && c1 != c2
  end

  def produce(str) do
    case String.length(str) do
      0 ->
        [""]

      1 ->
        [str]

      n ->
        half = div(n, 2)
        {front, back} = String.split_at(str, half)

        # t1 = Task.async(Logic, :produce, [front])
        # t2 = Task.async(Logic, :produce, [back])

        # merge(Task.await(t1), Task.await(t2))

        merge(
          produce(front),
          produce(back)
        )
    end
  end

  defp first(e) do
    case Enum.take(e, 1) do
      [] -> ""
      [x] -> x
    end
  end

  defp last(e) do
    case Enum.take(e, -1) do
      [] -> ""
      [x] -> x
    end
  end

  defp merge(front, back) do
    if match(last(front), first(back)) do
      merge(Enum.slice(front, 0..-2), Enum.slice(back, 1..-1))
    else
      front ++ back
    end
  end
end

[str] =
  File.stream!("input.txt")
  |> Stream.map(&String.trim/1)
  |> Enum.to_list()

Logic.produce(str)
# |> IO.inspect()
|> Enum.count()
|> IO.inspect()
