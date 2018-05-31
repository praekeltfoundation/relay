defmodule FakeVault do
  @moduledoc """
  A fake Vault API.
  """
  use GenServer

  defmodule State do
    defstruct auth_token: nil, listener: nil, kv_data: %{}
  end

  def reply(req, fv, status_code, json) do
    headers = %{"content-type" => "application/json"}
    {:ok, body} = Poison.encode(json)
    {:ok, :cowboy_req.reply(status_code, headers, body, req), fv}
  end

  def reply_error(req, fv, status_code, errors),
    do: reply(req, fv, status_code, %{"errors" => errors})

  def handle_authed(req, fv, handler) do
    valid_token = auth_token(fv)

    case req.headers["x-vault-token"] do
      ^valid_token -> handler.(req, fv)
      _ -> reply_error(req, fv, 403, ["permission denied"])
    end
  end

  defmodule VersionedKVDataHandler do
    @behaviour :cowboy_handler

    def init(req, fv), do: FakeVault.handle_authed(req, fv, &handle_req/2)

    defp handle_req(req, fv) do
      path = "/" <> Enum.join(:cowboy_req.path_info(req), "/")

      case FakeVault.get_kv_data(fv, path) do
        nil -> FakeVault.reply_error(req, fv, 404, [])
        data -> FakeVault.reply(req, fv, 200, build_response(data))
      end
    end

    defp build_response(data) do
      # NOTE: This ignores a bunch of response fields that are poorly
      # documented and that we don't care about anyway. It also uses some
      # hardcoded metadata because we don't care about that either, but
      # probably want it to at least be present.
      %{
        "data" => %{
          "data" => data,
          "metadata" => %{
            "created_time" => "2018-05-29T10:24:30.181952826Z",
            "deletion_time" => "",
            "destroyed" => false,
            "version" => 1
          }
        }
      }
    end
  end

  ## Client

  def start_link(args_and_opts) do
    {opts, args} = Keyword.split(args_and_opts, [:name])
    GenServer.start_link(__MODULE__, args, opts)
  end

  def port(fv), do: GenServer.call(fv, :port)
  def base_url(fv), do: "http://localhost:#{port(fv)}"
  def auth_token(fv), do: GenServer.call(fv, :auth_token)

  def get_kv_data(fv, path), do: GenServer.call(fv, {:get_kv_data, path})
  def set_kv_data(fv, path, data), do: GenServer.call(fv, {:set_kv_data, path, data})

  ## Callbacks

  def init(_opts) do
    # Trap exits so terminate/2 gets called reliably.
    Process.flag(:trap_exit, true)
    listener = make_ref()
    auth_token = UUID.uuid4()

    handlers = [
      {"/v1/secret/data/[...]", VersionedKVDataHandler, self()}
    ]

    dispatch = :cowboy_router.compile([{:_, handlers}])
    {:ok, _} = :cowboy.start_clear(listener, [], %{env: %{dispatch: dispatch}})
    {:ok, %State{auth_token: auth_token, listener: listener}}
  end

  def terminate(reason, state) do
    :cowboy.stop_listener(state.listener)
    reason
  end

  def handle_call(:port, _from, state), do: {:reply, :ranch.get_port(state.listener), state}
  def handle_call(:auth_token, _from, state), do: {:reply, state.auth_token, state}

  def handle_call({:get_kv_data, path}, _from, state) do
    {:reply, Map.get(state.kv_data, path), state}
  end

  def handle_call({:set_kv_data, path, data}, _from, state) do
    {:reply, :ok, %State{state | kv_data: Map.put(state.kv_data, path, data)}}
  end
end
