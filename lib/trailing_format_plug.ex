defmodule TrailingFormatPlug do
  @behaviour Plug

  def init(options), do: options

  def call(%{path_info: []} = conn, _opts), do: conn
  def call(conn, _opts) do
    path = conn.path_info |> List.last() |> String.split(".") |> Enum.reverse()

    case path do
      [ _ ] ->
        conn

      [ format | fragments ] ->
        new_path       = fragments |> Enum.reverse() |> Enum.join(".")
        path_fragments = if new_path == "", do: List.delete_at(conn.path_info, -1), else: List.replace_at conn.path_info, -1, new_path
        params         =
          Plug.Conn.fetch_query_params(conn).params
          |> update_params(new_path, format)
          |> Map.put("_format", format)

        %{
          conn |
          path_info: path_fragments,
          query_params: params,
          params: params
        }
    end
  end

  defp update_params(params, new_path, format) do
    wildcard = Enum.find params, fn {_, v} -> v == "#{new_path}.#{format}" end

    case wildcard do
      {key, _} ->
        Map.put(params, key, new_path)

      _ ->
        params
    end
  end
end
