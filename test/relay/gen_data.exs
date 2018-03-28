defmodule Relay.GenData do
  @moduledoc """
  StreamData generators for our own data structures.
  """
  require StreamData

  alias Relay.Resources.CertInfo

  @doc "Generate domains."
  def domain do
    prefix = StreamData.member_of([[], ["www"]])
    suffix = StreamData.member_of(["com", "org", "net", "health", "yt"])
    segment = StreamData.string(:alphanumeric, min_length: 1, max_length: 50)
    segments = StreamData.list_of(segment, min_length: 1, max_length: 3)

    StreamData.bind({prefix, segments, suffix}, fn {prefix, segments, suffix} ->
      [prefix, segments, [suffix]]
      |> Enum.concat()
      |> Enum.join(".")
      |> StreamData.constant()
    end)
  end

  @doc "Generate CertInfos."
  def cert_info do
    %{
      domains: StreamData.list_of(domain(), min_length: 1, max_length: 3),
      key: pem_data(:RSAPrivateKey),
      cert_chain: pem_data(:Certificate, max_length: 3)
    }
    |> StreamData.fixed_map()
    |> StreamData.map(&struct(CertInfo, &1))
  end

  defp pem_data(pem_type, opts \\ [max_length: 1]) do
    {pem_type, StreamData.binary(min_length: 10, max_length: 100), :not_encrypted}
    |> StreamData.list_of([{:min_length, 1} | opts])
    |> StreamData.map(&:public_key.pem_encode/1)
  end
end
