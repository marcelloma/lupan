defmodule Lupan do
  def retry do
    Lupan.DownloadQueue.retry()
  end
  def start_crawler do
    Crawly.Engine.start_spider(Lupan.Vimms.Crawler)
  end
end
