defmodule Lupan.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Lupan.DownloadQueue,
      Lupan.Downloader
    ]

    opts = [strategy: :one_for_one, name: Lupan.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
