defmodule MarathonClient do

  def stream_events(base_url, listeners, timeout \\ 60_000) do
    url = base_url <> "/v2/events"
    MarathonClient.SSEClient.start_link({url, listeners, timeout})
  end

  def get_apps(base_url) do
    url = base_url <> "/v2/apps"
    {:ok, %{status_code: 200, body: body}} = HTTPoison.get(url)
    JSX.decode(body)
  end

  def get_app_tasks(base_url, app_id) do
    url = "#{base_url}/v2/apps/#{String.trim(app_id, "/")}/tasks"
    {:ok, response} = HTTPoison.get(url)
    case response do
      %{status_code: 200, body: body} -> JSX.decode(body)
      %{status_code: 404, body: body} ->
        {:ok, message} = JSX.decode(body)
        {:error, Map.get(message, "message")}
    end
  end
end
