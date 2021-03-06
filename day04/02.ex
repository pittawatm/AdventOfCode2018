input_regex =
  ~r/\[(?<year>\d+)-(?<month>\d+)-(?<day>\d+)\s(?<hour>\d+):(?<minute>\d+)\]\s(?<event>[A-z#0-9\s]+)/

sorted_events =
  File.stream!("input.txt")
  |> Stream.map(&String.trim/1)
  |> Enum.map(&Regex.named_captures(input_regex, &1))
  |> Enum.map(
    &%{
      datetime:
        NaiveDateTime.new(
          String.to_integer(&1["year"]),
          String.to_integer(&1["month"]),
          String.to_integer(&1["day"]),
          String.to_integer(&1["hour"]),
          String.to_integer(&1["minute"]),
          0
        )
        |> Tuple.to_list()
        |> List.last()
        |> DateTime.from_naive("Etc/UTC")
        |> Tuple.to_list()
        |> List.last(),
      event: &1["event"]
    }
  )
  |> Enum.sort_by(fn d ->
    {d.datetime.year, d.datetime.month, d.datetime.day, d.datetime.hour, d.datetime.minute}
  end)

# |> IO.inspect()

guard_id_regex = ~r/[A-z\s]+#(?<id>\d+)[A-z\s]+/

ans =
  sorted_events
  |> Enum.reduce(
    %{
      guards: %{}
    },
    fn event, m ->
      cond do
        Regex.match?(guard_id_regex, event.event) ->
          id = Regex.named_captures(guard_id_regex, event.event) |> Map.get("id")

          new_m =
            if !Map.has_key?(m.guards, id) do
              Map.put(m, :guards, Map.put(m.guards, id, %{}))
            else
              m
            end

          Map.put(new_m, :current_id, id)

        event.event == "falls asleep" ->
          Map.put(m, :time_before, event.datetime)

        event.event == "wakes up" ->
          diff =
            Float.floor(DateTime.diff(event.datetime, m.time_before) / 60)
            |> Kernel.trunc()
            |> Kernel.-(1)

          m1 = m.time_before.minute

          m2 =
            if event.datetime.minute == 0 do
              59
            else
              event.datetime.minute - 1
            end

          diff_m = m2 - m1

          guards_map =
            if diff != diff_m do
              diff_m2 = m2
              diff_m1 = 60 - m1

              core = diff - diff_m2 - diff_m1
              round = Float.floor(core / 60) |> Kernel.trunc()

              Enum.reduce(
                [
                  Enum.reduce(0..59, %{}, fn m, mm ->
                    Map.put(mm, m, round)
                  end),
                  Enum.reduce(m1..59, %{}, fn m, mm ->
                    Map.put(mm, m, 1)
                  end),
                  Enum.reduce(0..m2, %{}, fn m, mm ->
                    Map.put(mm, m, 1)
                  end)
                ],
                Map.get(m.guards, m.current_id),
                fn m, acc -> Map.merge(m, acc, fn _k, v1, v2 -> v1 + v2 end) end
              )
            else
              Enum.reduce(m1..m2, Map.get(m.guards, m.current_id), fn m, mm ->
                Map.update(mm, m, 1, &(&1 + 1))
              end)
            end

          Map.put(m, :guards, Map.put(m.guards, m.current_id, guards_map))
      end
    end
  )

# IO.inspect(ans.guards)

{id, {minute, _count}} =
  Enum.reduce(Map.keys(ans.guards), %{}, fn gk, acc ->
    max_list =
      Map.get(ans.guards, gk)
      |> Map.to_list()

    if Enum.empty?(max_list) do
      acc
    else
      max = Enum.max_by(max_list, fn {_k, v} -> v end)
      Map.merge(acc, Map.new() |> Map.put(gk, max))
    end
  end)
  |> Map.to_list()
  # |> IO.inspect()
  |> Enum.max_by(fn {_id, {_minute, count}} -> count end)

IO.puts(String.to_integer(id) * minute)
