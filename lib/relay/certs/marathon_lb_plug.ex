defmodule Relay.Certs.MarathonLbPlug do
  @moduledoc """
  This plug pretends to be marathon-lb and translates the HTTP signal
  requests into cert update messages.
  """
  use Plug.Router

  plug :match
  plug :dispatch

  # We need to override this to get the GenServer ref into the conn so our
  # routes can see it.
  @impl Plug
  def call(conn, opts) do
    {cfs, opts} = Keyword.pop(opts, :cfs)

    conn
    |> put_private(:cfs, cfs)
    |> super(opts)
  end

  post "/_mlb_signal/:sig" when sig in ["hup", "usr1"] do
    GenServer.call(conn.private.cfs, :update_state)
    send_resp(conn, 204, "")
  end

  match _ do
    send_resp(conn, 404, "")
  end
end
