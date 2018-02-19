defmodule MarathonClient do
  def stream_events(base_url, listeners, timeout \\ 60_000) do
    url = base_url <> "/v2/events"
    MarathonClient.SSEClient.start_link({url, listeners, timeout})
  end

  defmodule ClientError do
    # These client error status codes are the ones listed as possible responses
    # in the Marathon RAML for the APIs we use.
    @status_code_reasons %{
      401 => :unauthorized,
      403 => :forbidden,
      404 => :not_found
    }

    defexception [:reason, :message]

    def new(status_code, %{"message" => message} = _message_json),
      do: %__MODULE__{reason: Map.get(@status_code_reasons, status_code), message: message}
  end

  defp marathon_response(%HTTPoison.Response{status_code: 200, body: body}), do: JSX.decode(body)

  defp marathon_response(%HTTPoison.Response{status_code: status_code, body: body})
       when status_code in 400..499 do
    {:ok, message} = JSX.decode(body)
    {:error, ClientError.new(status_code, message)}
  end

  defp get(base_url, path) do
    {:ok, response} = HTTPoison.get(base_url <> path)
    marathon_response(response)
  end

  def get_apps(base_url), do: get(base_url, "/v2/apps")

  def get_app_tasks(base_url, app_id),
    do: get(base_url, "/v2/apps/#{String.trim(app_id, "/")}/tasks")
end
