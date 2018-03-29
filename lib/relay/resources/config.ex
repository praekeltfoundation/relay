defmodule Relay.Resources.Config do
  @moduledoc """
  Common functions for accessing application configuration used in resources.
  """
  @spec envoy_config() :: keyword
  defp envoy_config, do: Application.fetch_env!(:relay, :envoy)

  @spec fetch_envoy_config!(atom) :: any
  def fetch_envoy_config!(key), do: envoy_config() |> Keyword.fetch!(key)

  @spec clusters_config() :: keyword
  defp clusters_config(), do: fetch_envoy_config!(:clusters)

  @spec fetch_clusters_config!(atom) :: any
  def fetch_clusters_config!(key), do: clusters_config() |> Keyword.fetch!(key)

  @spec endpoints_config() :: keyword
  defp endpoints_config, do: fetch_clusters_config!(:endpoints)

  @spec fetch_endpoints_config!(atom) :: any
  def fetch_endpoints_config!(key), do: endpoints_config() |> Keyword.fetch!(key)

  @spec listener_config(atom) :: keyword
  defp listener_config(listener), do: fetch_envoy_config!(:listeners) |> Keyword.fetch!(listener)

  @spec fetch_listener_config!(atom, atom) :: any
  def fetch_listener_config!(listener, key),
    do: listener |> listener_config() |> Keyword.fetch!(key)

  @spec get_listener_config(atom, atom, any) :: any
  def get_listener_config(listener, key, default),
    do: listener |> listener_config() |> Keyword.get(key, default)

  @spec marathon_acme_config() :: keyword
  defp marathon_acme_config, do: Application.fetch_env!(:relay, :marathon_acme)

  def fetch_marathon_acme_config!(key), do: marathon_acme_config() |> Keyword.fetch!(key)
end
