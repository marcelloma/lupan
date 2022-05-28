defmodule Lupan.Downloader do
  require Logger
  use GenStage

  def start_link([]) do
    GenStage.start_link(__MODULE__, [])
  end

  def init([]) do
    {:consumer, [], subscribe_to: [{Lupan.DownloadQueue, min_demand: 0, max_demand: 1}]}
  end

  def handle_events(games, _from, state) do
    tasks =
      Enum.map(games, fn game ->
        Task.async(fn ->
          Logger.info("Started Downloading #{inspect(game)}")

          {time, _} =
            :timer.tc(fn -> Lupan.Vimms.DownloaderMint.download(game) end)

          Logger.info("Downloaded #{inspect(game)} in #{time}")

          Lupan.DownloadQueue.mark_as_downloaded(game)
        end)
      end)

    Task.await_many(tasks, :infinity)

    {:noreply, [], state}
  end
end
