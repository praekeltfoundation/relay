defmodule Relay.Certs.VaultKV do
  @moduledoc """
  GenServer to update certs from a Vault KV store periodically and when a
  marathon-lb update request is received.
  """

  # Retry timeout in milliseconds
  @retry_timeout 1_000

  defmodule MarathonLbPlug do
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

  alias Plug.Adapters.Cowboy2
  alias Relay.{Certs, Resources, RetryStart}
  alias Relay.Resources.CertInfo

  use GenServer

  defmodule State do
    @moduledoc false
    # TODO: Better version management.
    defstruct [:resources, :sync_period, :vault_address, :vault_token, :vault_base_path, version: 1]

    @type t :: %__MODULE__{
            resources: GenServer.server(),
            sync_period: integer,
            vault_address: String.t(),
            vault_token: String.t(),
            vault_base_path: String.t(),
            version: integer
          }
  end

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts \\ []) do
    {resources, opts} = Keyword.pop(opts, :resources, Resources)
    GenServer.start_link(__MODULE__, resources, opts)
  end

  defp certs_cfg(key), do: Application.fetch_env!(:relay, :certs) |> Keyword.fetch!(key)

  @impl GenServer
  @spec init(GenServer.server()) :: {:ok, State.t()}
  def init(resources) do
    Process.flag(:trap_exit, true)

    # We may not have properly cleaned up after being killed, so handle an
    # existing listener if there is one.
    {:ok, _} =
      case start_mlb_listener() do
        {:error, {:already_started, _pid}} -> restart_mlb_listener()
        x -> x
      end

    state = %State{
      resources: resources,
      sync_period: certs_cfg(:sync_period),
      vault_address: certs_cfg(:vault_address),
      vault_token: certs_cfg(:vault_token),
      vault_base_path: certs_cfg(:vault_base_path)
    }

    {:ok, scheduled_update(state)}
  end

  defp start_mlb_listener do
    start_fun = fn ->
      Cowboy2.http(MarathonLbPlug, [cfs: self()], port: certs_cfg(:mlb_port))
    end

    RetryStart.retry_start(start_fun, @retry_timeout)
  end

  defp restart_mlb_listener do
    # TODO: Log a warning here?
    :ok = Cowboy2.shutdown(MarathonLbPlug.HTTP)
    start_mlb_listener()
  end

  @impl GenServer
  def terminate(reason, _state) do
    _ = Cowboy2.shutdown(MarathonLbPlug.HTTP)
    reason
  end

  @impl GenServer
  def handle_call(:update_state, _from, state) do
    {:reply, :ok, update_state(state)}
  end

  @impl GenServer
  def handle_info(:scheduled_update, state) do
    {:noreply, scheduled_update(state)}
  end

  defp scheduled_update(state) do
    Process.send_after(self(), :scheduled_update, state.sync_period)
    update_state(state)
  end

  @spec update_state(State.t()) :: State.t()
  defp update_state(state) do
    v = "#{state.version}"
    Resources.update_sni_certs(state.resources, v, read_sni_certs(state))
    %{state | version: state.version + 1}
  end

  @spec read_sni_certs(State.t()) :: [CertInfo.t()]
  defp read_sni_certs(s=%State{vault_address: addr, vault_token: token, vault_base_path: vbp}) do
    {:ok, resp} = VaultClient.read_kv(addr, "/secret", vbp <> "/live", token)
    %{"data" => %{"data" => live}} = resp
    live
    |> Map.keys()
    |> Enum.map(&read_sni_cert(&1, s))
  end

  @spec read_sni_cert(String.t(), State.t()) :: CertInfo.t()
  defp read_sni_cert(cert_path, s) do
    {:ok, resp} = VaultClient.read_kv(s.vault_address, "/secret", s.vault_base_path <> "/certificates/" <> cert_path, s.vault_token)
    %{"data" => %{"data" => fields}} = resp
    json_to_cert_info(fields)
  end

  defp json_to_cert_info(json) do
    json
    |> Map.take(["domains", "key", "cert_chain"])
    |> Enum.map(fn {k, v} -> {String.to_existing_atom(k), v} end)
    |> into_struct(CertInfo)
  end

  defp into_struct(kv_pairs, struct_module), do: struct(struct_module, kv_pairs)
end
