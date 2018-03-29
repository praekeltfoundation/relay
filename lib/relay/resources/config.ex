defmodule Relay.Resources.Config do
  @moduledoc """
  Common functions for accessing application configuration used in resources.
  """
  @spec envoy() :: keyword
  defp envoy, do: Application.fetch_env!(:relay, :envoy)

  @spec fetch_envoy!(atom) :: any
  def fetch_envoy!(key), do: envoy() |> Keyword.fetch!(key)

  @spec clusters() :: keyword
  defp clusters(), do: fetch_envoy!(:clusters)

  @spec fetch_clusters!(atom) :: any
  def fetch_clusters!(key), do: clusters() |> Keyword.fetch!(key)

  @spec endpoints() :: keyword
  defp endpoints, do: fetch_clusters!(:endpoints)

  @spec fetch_endpoints!(atom) :: any
  def fetch_endpoints!(key), do: endpoints() |> Keyword.fetch!(key)

  @spec listener(atom) :: keyword
  defp listener(listener), do: fetch_envoy!(:listeners) |> Keyword.fetch!(listener)

  @spec fetch_listener!(atom, atom) :: any
  def fetch_listener!(listener, key), do: listener |> listener() |> Keyword.fetch!(key)

  @spec get_listener_route_config_name(atom) :: String.t()
  def get_listener_route_config_name(listener),
    do: listener |> listener() |> Keyword.get(:route_config_name, Atom.to_string(listener))

  @spec marathon_acme() :: keyword
  defp marathon_acme, do: Application.fetch_env!(:relay, :marathon_acme)

  def fetch_marathon_acme!(key), do: marathon_acme() |> Keyword.fetch!(key)
end
