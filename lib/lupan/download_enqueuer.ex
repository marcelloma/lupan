defmodule Lupan.DownloadEnqueuer do
  @behaviour Crawly.Pipeline

  @impl Crawly.Pipeline
  def run(game, state) do
    Lupan.DownloadQueue.enqueue(game)

    {game, state}
  end
end
