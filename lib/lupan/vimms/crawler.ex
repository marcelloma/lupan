defmodule Lupan.Vimms.Crawler do
  use Crawly.Spider

  @base_url "https://vimm.net"

  @systems ["GBA"]

  @sections ?A..?Z
            |> Enum.map(& &1)
            |> List.to_string()
            |> String.split("")
            |> Enum.filter(&(&1 != ""))
            |> Enum.concat(["number"])

  @system_names %{"Game Boy Advance" => "gba"}

  @impl Crawly.Spider
  def base_url(), do: @base_url

  @impl Crawly.Spider
  def init() do
    start_urls =
      for system <- @systems, section <- @sections do
        "https://vimm.net/vault/?p=list&system=#{system}&section=#{section}"
      end

    [start_urls: start_urls]
  end

  @impl Crawly.Spider
  def parse_item(response) do
    {:ok, document} = Floki.parse_document(response.body)

    if game_url?(response.request_url),
      do: parse_game_document(document),
      else: parse_list_document(document)
  end

  defp parse_game_document(document) do
    id =
      document
      |> Floki.find("#download_form input[name=mediaId]")
      |> Floki.attribute("value")
      |> List.first()
      |> String.to_integer()

    system =
      document
      |> Floki.find("h2 > span:first-child")
      |> Floki.text()
      |> then(&Map.get(@system_names, &1))

    title =
      document
      |> Floki.find("h2 > span:last-child")
      |> Floki.text()

    _crc =
      document
      |> Floki.find("#data-crc")
      |> Floki.text()

    item = %{id: id, title: title, system: system}

    %Crawly.ParsedItem{items: [item], requests: []}
  end

  defp parse_list_document(document) do
    requests =
      document
      |> Floki.find(".mainContent:last-child > table")
      |> Floki.find("td:first-child a:first-child")
      |> Floki.attribute("href")
      |> Enum.filter(&game_url?/1)
      |> Enum.map(&build_absolute_url/1)
      |> Enum.map(&Crawly.Utils.request_from_url/1)

    %Crawly.ParsedItem{items: [], requests: requests}
  end

  defp build_absolute_url(url), do: URI.merge(base_url(), url) |> to_string()

  def game_url?(url), do: String.match?(url, ~r/\/vault\/\d/)
end
