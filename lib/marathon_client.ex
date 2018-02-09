defmodule Relay.MarathonClient do

  def stream_events(base_url, listeners, timeout \\ 60_000) do
    url = base_url <> "/v2/events"
    Relay.MarathonClient.SSEClient.start_link({url, listeners, timeout})
  end
end
