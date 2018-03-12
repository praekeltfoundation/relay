defmodule Relay.Certs do

  # This is a somewhat loose regex designed to exclude things that obviously
  # aren't hostnames. It will allow some non-hostnames, because full validation
  # would be a lot more complex.
  @hostname_regex ~r/^[a-zA-Z0-9.-]+$/

  @doc """
  Extracts the subject CNs and SAN DNS names from the given certificate to
  determine which SNI hostnames to serve it for.
  """
  @spec get_hostnames(:relay_pk_utils.cert) :: [String.t]
  def get_hostnames(cert) do
    :relay_pk_utils.get_cert_names(cert)
    |> Enum.map(&to_string/1)
    |> Enum.filter(&String.match?(&1, @hostname_regex))
    |> Enum.uniq()
  end

  @doc """
  Extracts hostnames from all end-entity certs in the given PEM data. In order
  to support self-signed certs (which may look a lot like CA certs), we assume
  that if there's only one cert in the PEM data it's the one we want.
  """
  @spec get_end_entity_hostnames(binary | [:public_key.pem_entry]) :: [String.t]
  def get_end_entity_hostnames(pem_data) when is_binary(pem_data),
    do: get_end_entity_hostnames(:public_key.pem_decode(pem_data))

  def get_end_entity_hostnames(pem_entries) do
    pem_entries
    |> filter_certs()
    |> Enum.flat_map(&get_hostnames/1)
    |> Enum.uniq()
  end

  defp filter_certs(pem_entries) do
    case Enum.filter(pem_entries, &is_cert/1) do
      [cert] -> [cert]
      certs -> :relay_pk_utils.get_end_entity_certs(certs)
    end
  end

  defp is_cert({:Certificate, _, _}), do: true
  defp is_cert(_), do: false
end
