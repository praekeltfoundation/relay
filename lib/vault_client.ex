defmodule VaultClient do
  @moduledoc """
  A very basic Vault API client. Currently supports the minimum functionality
  necessary for Relay to authenticate and read K/V data.
  """
  alias HTTPoison.Response

  # The next version of Poison will have an error type, so this will need to change.
  @typep poison_decode_error :: {:error, :invalid} | {:error, {:invalid, String.t()}}
  @typep poison_decode_result :: {:ok, Poison.Parser.t()} | poison_decode_error
  @typep client_error :: {:error, {integer, map}}
  @type response :: poison_decode_result | client_error

  defp vault_response(%Response{status_code: 200, body: body}), do: Poison.decode(body)

  defp vault_response(%Response{status_code: status_code, body: body})
       when status_code in 400..499 do
    {:ok, message} = Poison.decode(body)
    {:error, {status_code, message}}
  end

  defp get(base_url, path, token, options \\ []) do
    headers = ["X-Vault-Token": token]
    {:ok, response} = HTTPoison.get(base_url <> "/v1" <> path, headers, options)
    vault_response(response)
  end

  def read_kv(base_url, base_path, kv_path, token) do
    path = base_path <> "/data" <> kv_path
    get(base_url, path, token)
  end
end
