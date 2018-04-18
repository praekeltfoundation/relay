defmodule Relay.Certs.Filesystem do
  @moduledoc """
  GenServer to update certs from the filesystem periodically and when a
  marathon-lb update request is received.
  """

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
  alias Relay.{Certs, Resources}
  alias Relay.Resources.CertInfo

  use GenServer

  defmodule State do
    @moduledoc false
    # TODO: Better version management.
    defstruct [:resources, :sync_period, :cert_paths, version: 1]

    @type t :: %__MODULE__{
            resources: GenServer.server(),
            sync_period: integer,
            cert_paths: [Path.t()],
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
    # TODO: Make this port number configurable.
    Cowboy2.http(MarathonLbPlug, [cfs: self()], port: 9090)

    state = %State{
      resources: resources,
      sync_period: certs_cfg(:sync_period),
      cert_paths: certs_cfg(:paths)
    }

    {:ok, scheduled_update(state)}
  end

  @impl GenServer
  def terminate(reason, _state) do
    Cowboy2.shutdown(MarathonLbPlug.HTTP)
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
  defp read_sni_certs(%State{cert_paths: cert_paths}) do
    cert_paths
    |> Enum.flat_map(&Path.wildcard("#{&1}/*"))
    |> Enum.filter(&File.regular?/1)
    |> Enum.map(&read_sni_cert/1)
  end

  @spec read_sni_cert(Path.t()) :: CertInfo.t()
  defp read_sni_cert(cert_path) do
    cert_path
    |> File.read!()
    |> pem_to_cert_info()
  end

  defp pem_to_cert_info(cert_bundle) do
    {:ok, key} = Certs.get_key(cert_bundle)
    certs = Certs.get_certs(cert_bundle)
    sni_domains = Certs.get_end_entity_hostnames(certs)

    %CertInfo{
      domains: sni_domains,
      key: Certs.pem_encode(key),
      cert_chain: Certs.pem_encode(certs)
    }
  end
end
