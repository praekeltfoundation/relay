defmodule Relay.GenData do
  @moduledoc """
  StreamData generators for our own data structures.
  """
  require StreamData

  alias Relay.Resources.{AppEndpoint, CertInfo}

  alias Envoy.Api.V2.Cluster.LbPolicy
  alias Google.Protobuf.Duration

  @doc "Generate a non-empty list."
  def nonempty_list_of(data, opts \\ []),
    do: StreamData.list_of(data, Keyword.put_new(opts, :min_length, 1))

  @doc "Generate a struct."
  def struct_of(map, mod), do: map |> StreamData.fixed_map() |> StreamData.map(&struct(mod, &1))

  @doc "Generate domains."
  def domain do
    prefix = StreamData.member_of([[], ["www"]])
    suffix = StreamData.member_of(["com", "org", "net", "health", "yt"])
    segment = StreamData.string(:alphanumeric, min_length: 1, max_length: 50)
    segments = nonempty_list_of(segment, max_length: 3)

    StreamData.map({prefix, segments, suffix}, fn {prefix, segments, suffix} ->
      [prefix, segments, suffix]
      |> List.flatten()
      |> Enum.join(".")
    end)
  end

  @doc "Generate CertInfos."
  def cert_info do
    %{
      domains: nonempty_list_of(domain(), max_length: 3),
      key: pem_data(:RSAPrivateKey),
      cert_chain: pem_data(:Certificate, max_length: 3)
    }
    |> struct_of(CertInfo)
  end

  defp pem_data(pem_type, opts \\ [max_length: 1]) do
    {pem_type, StreamData.binary(min_length: 10, max_length: 100), :not_encrypted}
    |> nonempty_list_of(opts)
    |> StreamData.map(&:public_key.pem_encode/1)
  end

  @doc "Generate AppEndpoints."
  def app_endpoint do
    %{
      name: app_name(),
      cluster_opts: cluster_opts()
    }
    |> struct_of(AppEndpoint)
  end

  defp app_name(opts \\ [max_length: 2]) do
    StreamData.string(:ascii)
    |> StreamData.map(&("/" <> &1))
    |> nonempty_list_of(opts)
    |> StreamData.map(&Enum.join/1)
  end

  defp cluster_opts do
    StreamData.optional_map(
      connect_timeout: connect_timeout(),
      lb_policy: lb_policy()
    )
    |> StreamData.map(&Map.to_list/1)
  end

  defp connect_timeout do
    StreamData.positive_integer() |> StreamData.map(&Duration.new(seconds: &1))
  end

  defp lb_policy do
    [:ROUND_ROBIN, :LEAST_REQUEST, :RING_HASH, :RANDOM, :ORIGINAL_DST_LB, :MAGLEV]
    |> StreamData.member_of()
    |> StreamData.map(&LbPolicy.value/1)
  end
end
