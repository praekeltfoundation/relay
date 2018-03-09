defmodule Relay.Marathon.App do
  alias Relay.Marathon.{Labels, Networking}

  defstruct [:id, :networking_mode, :ports_list, :port_indices_in_group, :labels, :version]
  @type t :: %__MODULE__{
    id: String.t,
    networking_mode: Networking.networking_mode,
    ports_list: [Networking.port_number],
    port_indices_in_group: [non_neg_integer],
    labels: Labels.labels,
    version: String.t
  }

  @spec from_definition(map, String.t) :: t
  def from_definition(%{"id" => id, "labels" => labels} = app, group) do
    ports_list = Networking.ports_list(app)
    %__MODULE__{
      id: id,
      networking_mode: Networking.networking_mode(app),
      ports_list: ports_list,
      port_indices_in_group: port_indices_in_group(ports_list, labels, group),
      labels: labels,
      version: version(app)
    }
  end

  @spec from_event(map, String.t) :: t
  def from_event(%{"eventType" => "api_post_event", "appDefinition" => definition} = _event, group),
    do: from_definition(definition, group)

  defp port_indices_in_group([], _labels, _group), do: []

  @spec port_indices_in_group([Networking.port_number], %{String.t => String.t}, String.t) :: [non_neg_integer]
  defp port_indices_in_group(ports_list, labels, group) do
    0..(length(ports_list) - 1)
    |> Enum.filter(fn port_index -> Labels.marathon_lb_group(labels, port_index) == group end)
  end

  @spec version(map) :: String.t()
  defp version(app) do
    case app do
      # In most cases the `lastConfigChangeAt` value should be available...
      %{"versionInfo" => %{"lastConfigChangeAt" => version}} -> version
      # ...but if this is an app that hasn't been changed yet then use `version`
      %{"version" => version} -> version
    end
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
