defmodule Relay.Certs do

  # This is a somewhat loose regex designed to exclude things that obviously
  # aren't hostnames. It will allow some non-hostnames, because full validation
  # would be a lot more complex.
  @hostname_regex ~r/^[a-zA-Z0-9.-]+$/

  def get_hostnames(cert) do
    :pk_utils.get_cert_names(cert)
    |> Enum.map(&to_string/1)
    |> Enum.filter(&String.match?(&1, @hostname_regex))
    |> Enum.uniq()
  end
end
