defmodule Relay.Resources do
  alias Relay.Publisher

  defmodule CertInfo do
    defstruct [:domains, :key, :cert_chain]
    # key and cert_chain are PEM-encoded strings.
    @type t :: %__MODULE__{
            domains: [String.t()],
            key: String.t(),
            cert_chain: String.t()
          }
  end

  # FIXME: This needs a better name.
  defmodule AppPortInfo do
    defstruct [:name, cluster_opts: []]

    @type t :: %__MODULE__{
            name: String.t(),
            cluster_opts: keyword
          }
  end

  use GenServer

  defmodule State do
    defstruct sni_certs: {"", []}

    @type t :: %__MODULE__{
            sni_certs: {String.t(), [Relay.Resources.CertInfo.t()]}
          }
  end

  ## Client interface

  def start_link(opts \\ []) do
    {publisher, opts} = Keyword.pop(opts, :publisher, Relay.Publisher)
    GenServer.start_link(__MODULE__, publisher, opts)
  end

  @spec update_sni_certs(GenServer.server(), String.t(), [CertInfo.t()]) :: :ok
  def update_sni_certs(server, version, cert_infos),
    do: GenServer.call(server, {:update_sni_certs, version, cert_infos})

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

  ## Internals

  defp publish_lds(pub, state) do
    {version, cert_infos} = state.sni_certs
    listeners = Relay.Resources.LDS.listeners(cert_infos)
    Publisher.update(pub, :lds, version, listeners)
  end

  defp update_sni_certs_state(state, version, cert_infos) do
    # FIXME: Version check, etc.
    %{state | sni_certs: {version, cert_infos}}
  end
end
