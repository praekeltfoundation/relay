defmodule Relay.MarathonClient do

  def stream_events(base_url, listeners, timeout \\ 60_000) do
    url = base_url <> "/v2/events"
    Relay.MarathonClient.SSEClient.start_link({url, listeners, timeout})
  end

  def get_apps(base_url) do
    url = base_url <> "/v2/apps"
    {:ok, %{status_code: 200, body: body}} = HTTPoison.get(url)
    JSX.decode(body)
  end
end
