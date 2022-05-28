defmodule Lupan.Vimms.DownloaderMint do
  def download(%{id: id} = game) do
    {:ok, conn} = Mint.HTTP.connect(:https, "download2.vimm.net", 443)
    {:ok, conn, _request_ref} = Mint.HTTP.request(conn, "GET", "/download/?mediaId=#{id}", headers(), "")

    %{game: game, conn: conn, file: nil}
    |> Stream.unfold(&stream_response/1)
    |> Stream.run()

    Mint.HTTP.close(conn)
  end

  defp stream_response(nil), do: nil
  defp stream_response(%{conn: conn} = state) do
    receive do
      message ->
        case Mint.HTTP.stream(conn, message) do
          :unknown ->
            nil

          {:ok, conn, responses} ->
            new_state = %{state | conn: conn}
            new_state = Enum.reduce(responses, new_state, & parse_response/2)
            {state, new_state}
        end
    end
  end

  defp parse_response(response, %{game: game} =state) do
    case response do
      {:status, _request_ref, 200} ->
        state

      {:headers, _request_ref, headers} ->
        file = create_file("roms/#{game.system}", headers)
        %{state | file: file}

      {:data, _request_ref, chunk} ->
        IO.binwrite(state.file, chunk)
        state

      {:done, _request_ref} ->
        File.close(state.file)
        nil
    end
  end

  defp headers(), do: [origin_header(), referer_header(), user_agent_header()]

  defp user_agent_header(),
    do:
      {"User-Agent",
       "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36"}

  defp origin_header(), do: {"Origin", "vimm.net"}

  defp referer_header(), do: {"Referer", "https://vimm.net/"}

  defp create_file(location, headers) do
    file_name =
      headers
      |> Enum.into(%{})
      |> Map.get("content-disposition")
      |> String.split("filename=\"")
      |> List.last()
      |> String.replace("\"", "")

    File.mkdir_p(location)

    {:ok, file_pid} =
      [".", location, file_name]
      |> Path.join()
      |> File.open([:write, :binary])

    file_pid
  end
end
