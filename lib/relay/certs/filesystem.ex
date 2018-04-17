defmodule Relay.Certs.Filesystem do
  @moduledoc """
  GenServer to update certs from the filesystem periodically and when a
  marathon-lb update request is received.
  """

  alias Relay.{Certs, Resources}
  alias Relay.Resources.CertInfo

  use GenServer

  defmodule State do
    @moduledoc false
    # TODO: Make delay configurable.
    # TODO: Better version management.
    defstruct resources: Resources, delay: 1_000, cert_paths: [], version: 1

    @type t :: %__MODULE__{
            resources: GenServer.server(),
            delay: integer,
            cert_paths: [Path.t()],
            version: integer
          }
  end

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts \\ []) do
    {resources, opts} = Keyword.pop(opts, :resources, Resources)
    GenServer.start_link(__MODULE__, resources, opts)
  end

  @impl GenServer
  @spec init(GenServer.server()) :: {:ok, State.t()}
  def init(resources) do
    cert_paths = Application.fetch_env!(:relay, :certs) |> Keyword.fetch!(:paths)
    state = scheduled_update(%State{resources: resources, cert_paths: cert_paths})
    {:ok, state}
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
    Process.send_after(self(), :scheduled_update, state.delay)
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
