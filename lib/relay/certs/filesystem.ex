defmodule Relay.Certs.Filesystem do
  @moduledoc """
  GenServer to update certs from the filesystem periodically and when a
  marathon-lb update request is received.
  """

  # Retry timeout in milliseconds
  @retry_timeout 1_000

  alias Plug.Cowboy
  alias Relay.{Certs, Resources, RetryStart}
  alias Relay.Certs.MarathonLbPlug
  alias Relay.Resources.CertInfo

  use LogWrapper, as: Log

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
      cert_paths: certs_cfg(:paths)
    }

    {:ok, scheduled_update(state)}
  end

  defp start_mlb_listener do
    start_fun = fn ->
      Cowboy.http(MarathonLbPlug, [cfs: self()], port: certs_cfg(:mlb_port))
    end

    RetryStart.retry_start(start_fun, @retry_timeout)
  end

  defp restart_mlb_listener do
    # TODO: Log a warning here?
    :ok = Cowboy.shutdown(MarathonLbPlug.HTTP)
    start_mlb_listener()
  end

  @impl GenServer
  def terminate(reason, _state) do
    _ = Cowboy.shutdown(MarathonLbPlug.HTTP)
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
    Log.debug("Performing scheduled update of certificates from the filesystem")
    Process.send_after(self(), :scheduled_update, state.sync_period)
    update_state(state)
  end

  @spec update_state(State.t()) :: State.t()
  defp update_state(state) do
    v = "#{state.version}"
    certs = read_sni_certs(state)
    Log.debug("Read #{length(certs)} certificates from the filesystem for version #{v}")
    Resources.update_sni_certs(state.resources, v, certs)
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
    server_names = Certs.get_end_entity_hostnames(certs)

    %CertInfo{
      domains: server_names,
      key: Certs.pem_encode(key),
      cert_chain: Certs.pem_encode(certs)
    }
  end
end
