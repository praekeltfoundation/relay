defmodule Relay.Marathon.App do
  alias Relay.Marathon.{Labels, Networking}

  defstruct [:id, :networking_mode, :ports_list, :labels, :version]
  @type t :: %__MODULE__{
    id: String.t,
    networking_mode: Networking.networking_mode,
    ports_list: [Networking.port_number],
    labels: Labels.labels,
    version: String.t
  }

  @spec from_definition(map) :: t
  def from_definition(%{"id" => id, "labels" => labels} = app) do
    %__MODULE__{
      id: id,
      networking_mode: Networking.networking_mode(app),
      ports_list: Networking.ports_list(app),
      labels: labels,
      version: config_version(app)
    }
  end

  defp config_version(%{"versionInfo" => %{"lastConfigChangeAt" => version}}), do: version

  def port_indices_in_group(%__MODULE__{ports_list: []}, _group), do: []

  @spec port_indices_in_group(t, String.t) :: [non_neg_integer]
  def port_indices_in_group(%__MODULE__{ports_list: ports_list, labels: labels}, group) do
    0..(length(ports_list) - 1)
    |> Enum.filter(fn port_index -> Labels.marathon_lb_group(labels, port_index) == group end)
  end

  @spec marathon_lb_vhost(t, non_neg_integer) :: [String.t]
  def marathon_lb_vhost(%__MODULE__{labels: labels}, port_index),
    do: Labels.marathon_lb_vhost(labels, port_index)

  @spec marathon_lb_redirect_to_https?(t, non_neg_integer) :: boolean
  def marathon_lb_redirect_to_https?(%__MODULE__{labels: labels}, port_index),
    do: Labels.marathon_lb_redirect_to_https?(labels, port_index)

  @spec marathon_acme_domain(t, non_neg_integer) :: [String.t]
  def marathon_acme_domain(%__MODULE__{labels: labels}, port_index),
    do: Labels.marathon_acme_domain(labels, port_index)
end
