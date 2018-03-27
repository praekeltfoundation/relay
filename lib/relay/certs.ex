defmodule Relay.Certs do
  @moduledoc """
  Utilities for working with PEM-encoded certificates.
  """

  @typep pem_entry :: :public_key.pem_entry()

  # This is a somewhat loose regex designed to exclude things that obviously
  # aren't hostnames. It will allow some non-hostnames, because full validation
  # would be a lot more complex.
  @hostname_regex ~r/^[a-zA-Z0-9.-]+$/

  @key_types [:RSAPrivateKey, :DSAPrivateKey, :ECPrivateKey]

  @doc """
  Encodes the given PEM data (either a single entry, a list of entries, or an
  already-encoded binary) in PEM format.
  """
  @spec pem_encode(binary | pem_entry | [pem_entry]) :: binary
  def pem_encode(pem_data) when is_binary(pem_data), do: pem_data
  def pem_encode({_, _, _} = pem_data), do: pem_encode([pem_data])
  def pem_encode(pem_data), do: :public_key.pem_encode(pem_data)

  @doc """
  Extracts the subject CNs and SAN DNS names from the given certificate to
  determine which SNI hostnames to serve it for.
  """
  @spec get_hostnames(:relay_pk_utils.cert()) :: [String.t()]
  def get_hostnames(cert) do
    cert
    |> :relay_pk_utils.get_cert_names()
    |> Enum.map(&to_string/1)
    |> Enum.filter(&String.match?(&1, @hostname_regex))
    |> Enum.uniq()
  end

  @doc """
  Returns a list of all certificates in the given PEM data.
  """
  @spec get_certs(binary | [pem_entry]) :: [pem_entry]
  def get_certs(pem_data) do
    pem_data
    |> pem_decode()
    |> Enum.filter(fn {pem_type, _, _} -> pem_type == :Certificate end)
  end

  @doc """
  Gets the first key in the given PEM data. Returns `{:ok, key}` if there is at
  least one key, otherwise `:error`.
  """
  @spec get_key(binary | [pem_entry]) :: {:ok, pem_entry} | :error
  def get_key(pem_data) do
    pem_data
    |> pem_decode()
    |> Enum.filter(fn {pem_type, _, _} -> pem_type in @key_types end)
    |> Enum.fetch(0)
  end

  defp pem_decode(pem_data) when is_list(pem_data), do: pem_data
  defp pem_decode(pem_data), do: :public_key.pem_decode(pem_data)

  @doc """
  Extracts hostnames from all end-entity certs in the given PEM data. In order
  to support self-signed certs (which may look a lot like CA certs), we assume
  that if there's only one cert in the PEM data it's the one we want.
  """
  @spec get_end_entity_hostnames(binary | [pem_entry]) :: [String.t()]
  def get_end_entity_hostnames(pem_data) do
    pem_data
    |> get_certs()
    |> get_end_entity_certs()
    |> Enum.flat_map(&get_hostnames/1)
    |> Enum.uniq()
  end

  defp get_end_entity_certs([cert]), do: [cert]
  defp get_end_entity_certs(certs), do: :relay_pk_utils.get_end_entity_certs(certs)
end
