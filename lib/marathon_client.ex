defmodule MarathonClient do
  @moduledoc """
  A very basic Marathon API client. Currently supports the minimum
  functionality necessary for Relay to watch events and fetch app and task
  information.
  """
  alias HTTPoison.Response

  # The next version of Poison will have an error type, so this will need to change.
  @typep poison_decode_error :: {:error, :invalid} | {:error, {:invalid, String.t()}}
  @typep poison_decode_result :: {:ok, Poison.Parser.t()} | poison_decode_error
  @typep client_error :: {:error, {integer, map}}
  @type response :: poison_decode_result | client_error

  @spec stream_events(String.t(), [pid], non_neg_integer) :: GenServer.on_start()
  def stream_events(base_url, listeners, timeout \\ 60_000) do
    url = base_url <> "/v2/events"
    __MODULE__.SSEClient.start_link({url, listeners, timeout})
  end

  defp marathon_response(%Response{status_code: 200, body: body}), do: Poison.decode(body)

  defp marathon_response(%Response{status_code: status_code, body: body})
       when status_code in 400..499 do
    {:ok, message} = Poison.decode(body)
    {:error, {status_code, message}}
  end

  defp get(base_url, path, options \\ []) do
    {:ok, response} = HTTPoison.get(base_url <> path, [], options)
    marathon_response(response)
  end

  @doc """
  Get all Marathon apps.

  Args:
    * `base_url` - The base URL for the Marathon instance.

  Options:
    * `:embed` - A list of nested resources to embed in the response. e.g.
      `embed: ["apps.tasks"]`.
  """
  @spec get_apps(String.t(), keyword) :: response
  def get_apps(base_url, options \\ []) do
    get_options =
      case Keyword.get(options, :embed, []) do
        [] -> []
        embed -> [params: Enum.map(embed, fn val -> {:embed, val} end)]
      end

    get(base_url, "/v2/apps", get_options)
  end

  @spec get_app_tasks(String.t(), String.t()) :: response
  def get_app_tasks(base_url, app_id),
    do: get(base_url, "/v2/apps/#{String.trim(app_id, "/")}/tasks")
end
