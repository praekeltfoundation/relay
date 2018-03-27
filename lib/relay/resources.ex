defmodule Relay.Resources do
  @moduledoc """
  Relay.Resources is a GenServer that listens for state updates on cluster
  resources and sends the appropriate Envoy resource updates to
  Relay.Publisher.
  """

  alias Relay.Publisher
  alias __MODULE__.{CertInfo, AppEndpoint, LDS, CDS, EDS, RDS}

  defmodule CertInfo do
    @moduledoc "Certificate data for SNI."
    defstruct [:domains, :key, :cert_chain]
    # key and cert_chain are PEM-encoded strings.
    @type t :: %__MODULE__{
            domains: [String.t()],
            key: String.t(),
            cert_chain: String.t()
          }
  end

  defmodule AppEndpoint do
    @moduledoc "All the stuff we need to know about a cluster 'application'."
    defstruct [
      :name,
      domains: [],
      addresses: [],
      marathon_acme_domains: [],
      redirect_to_https: false,
      cluster_opts: [],
      cla_opts: [],
      llb_endpoint_opts: [],
      lb_endpoint_opts: []
    ]

    @type t :: %__MODULE__{
            name: String.t(),
            domains: [String.t()],
            addresses: [{String.t(), :inet.port_number()}],
            marathon_acme_domains: [String.t()],
            redirect_to_https: boolean,
            cluster_opts: keyword,
            cla_opts: keyword,
            llb_endpoint_opts: keyword,
            lb_endpoint_opts: keyword
          }
  end

  use GenServer

  defmodule State do
    @moduledoc false
    defstruct sni_certs: {"", []}, app_endpoints: {"", []}

    @type t :: %__MODULE__{
            sni_certs: {String.t(), [CertInfo.t()]},
            app_endpoints: {String.t(), [AppEndpoint.t()]}
          }
  end

  ## Client interface

  def start_link(opts \\ []) do
    {publisher, opts} = Keyword.pop(opts, :publisher, Publisher)
    GenServer.start_link(__MODULE__, publisher, opts)
  end

  @spec update_sni_certs(GenServer.server(), String.t(), [CertInfo.t()]) :: :ok
  def update_sni_certs(server, version, cert_infos),
    do: GenServer.call(server, {:update_sni_certs, version, cert_infos})

  @spec update_app_endpoints(GenServer.server(), String.t(), [AppEndpoint.t()]) :: :ok
  def update_app_endpoints(server, version, app_endpoints),
    do: GenServer.call(server, {:update_app_endpoints, version, app_endpoints})

  ## Server callbacks

  @spec init(GenServer.server()) :: {:ok, {GenServer.server(), State.t()}}
  def init(publisher) do
    {:ok, {publisher, %State{}}}
  end

  def handle_call({:update_sni_certs, version, cert_infos}, _from, {pub, state}) do
    new_state = update_sni_certs_state(state, version, cert_infos)
    publish_lds(pub, new_state)
    {:reply, :ok, {pub, new_state}}
  end

  def handle_call({:update_app_endpoints, version, app_endpoints}, _from, {pub, state}) do
    new_state = update_app_endpoints_state(state, version, app_endpoints)
    publish_cds(pub, new_state)
    publish_rds(pub, new_state)
    publish_eds(pub, new_state)
    {:reply, :ok, {pub, new_state}}
  end

  ## Internals

  defp publish_lds(pub, state) do
    {version, cert_infos} = state.sni_certs
    Publisher.update(pub, :lds, version, LDS.listeners(cert_infos))
  end

  defp publish_cds(pub, state) do
    {version, app_endpoints} = state.app_endpoints
    Publisher.update(pub, :cds, version, CDS.clusters(app_endpoints))
  end

  defp publish_rds(pub, state) do
    {version, app_endpoints} = state.app_endpoints
    Publisher.update(pub, :rds, version, RDS.routes(app_endpoints))
  end

  defp publish_eds(pub, state) do
    {version, app_endpoints} = state.app_endpoints
    Publisher.update(pub, :eds, version, EDS.cluster_load_assignments(app_endpoints))
  end

  defp update_sni_certs_state(state, version, cert_infos) do
    # FIXME: Version check, etc.
    %{state | sni_certs: {version, cert_infos}}
  end

  defp update_app_endpoints_state(state, version, app_endpoints) do
    # FIXME: Version check, etc.
    %{state | app_endpoints: {version, app_endpoints}}
  end
end
