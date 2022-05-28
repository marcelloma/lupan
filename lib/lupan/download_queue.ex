defmodule Lupan.DownloadQueue do
  use GenStage

  def start_link([]) do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  def enqueue(game) do
    GenServer.cast(__MODULE__, {:enqueue, game})
  end

  def retry() do
    GenServer.cast(__MODULE__, :retry)
  end

  def mark_as_downloaded(game) do
    GenServer.cast(__MODULE__, {:mark_as_downloaded, game})
  end

  @impl GenStage
  def init([]) do
    {:ok, dets} = :dets.open_file(:cache, type: :set)
    {:producer, dets}
  end

  @impl GenStage
  def handle_demand(_demand, dets) do
    {:noreply, [], dets}
  end

  @impl GenStage
  def handle_cast(:retry, dets) do
    missing_games =
      dets
      |> :dets.select([{{:_, :_, :_, false}, [], [:"$_"]}])
      |> Enum.map(fn {id, system, title, _} -> %{id: id, title: title, system: system} end)

    missing_games
    |> IO.inspect(label: "Missing Games")
    |> length()
    |> IO.inspect(label: "Missing Games Count")

    {:noreply, missing_games, dets}
  end

  @impl GenStage
  def handle_cast({:enqueue, game}, dets) do
    game_tuple =
      game
      |> Map.values()
      |> Enum.concat([false])
      |> List.to_tuple()

    case :dets.insert_new(dets, game_tuple) do
      true ->
        {:noreply, [], dets}

      false ->
        {:noreply, [], dets}
    end
  end

  @impl GenStage
  def handle_cast({:mark_as_downloaded, game}, dets) do
    game_values = Map.values(game)

    pending_tuple = List.to_tuple(game_values ++ [false])
    downloaded_tuple = List.to_tuple(game_values ++ [true])

    :ok = :dets.delete_object(dets, pending_tuple)
    :ok = :dets.insert(dets, downloaded_tuple)

    {:noreply, [], dets}
  end
end
