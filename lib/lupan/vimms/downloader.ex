defmodule Lupan.Vimms.Downloader do
  # 1722

  def download(%{id: id} = game) do
    response =
      HTTPoison.get!(
        "https://download2.vimm.net/download/",
        headers(),
        params: %{mediaId: id},
        stream_to: self(),
        async: :once,
        hackney: [pool: false]
      )

    stream_to_file(game, response, nil)
  end

  defp stream_to_file(game, response, file_pid) do
    response_id = response.id

    receive do
      %HTTPoison.AsyncStatus{code: 200, id: ^response_id} ->
        HTTPoison.stream_next(response)
        stream_to_file(game, response, file_pid)

      %HTTPoison.AsyncHeaders{headers: headers, id: ^response_id} ->
        file =
          headers
          |> Enum.into(%{})
          |> Map.get("Content-Disposition")
          |> String.split("filename=\"")
          |> List.last()
          |> String.replace("\"", "")

        folder = "roms/#{game.system}"

        File.mkdir_p(folder)

        {:ok, file_pid} =
          [".", folder, file]
          |> Path.join()
          |> File.open([:write, :binary])

        HTTPoison.stream_next(response)
        stream_to_file(game, response, file_pid)

      %HTTPoison.AsyncChunk{chunk: chunk, id: ^response_id} ->
        IO.binwrite(file_pid, chunk)
        HTTPoison.stream_next(response)
        stream_to_file(game, response, file_pid)

      %HTTPoison.AsyncEnd{id: ^response_id} ->
        File.close(file_pid)
    end
  end

  defp headers(), do: [origin_header(), referer_header(), user_agent_header()]

  defp user_agent_header(),
    do:
      {"User-Agent",
       "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36"}

  defp origin_header(), do: {"Origin", "vimm.net"}

  defp referer_header(), do: {"Referer", "https://vimm.net/"}
end
