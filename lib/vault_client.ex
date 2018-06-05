defmodule VaultClient do
  @moduledoc """
  A very basic Vault API client. Currently supports the minimum functionality
  necessary for Relay to authenticate and read K/V data.
  """
  alias HTTPoison.Response

  defmodule ClientConfig do
    defstruct [:base_url, :token, engine_path: "/secret", kv_path_prefix: ""]

    @type t :: %__MODULE__{
            base_url: String.t(),
            token: String.t(),
            engine_path: String.t(),
            kv_path_prefix: String.t()
          }
  end

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

  defp get(%ClientConfig{base_url: base_url, token: token}, path, options \\ []) do
    headers = ["X-Vault-Token": token]
    {:ok, response} = HTTPoison.get(base_url <> "/v1" <> path, headers, options)
    vault_response(response)
  end

  def read_kv(cfg, kv_path) do
    path = cfg.engine_path <> "/data" <> cfg.kv_path_prefix <> kv_path
    get(cfg, path)
  end

  def read_kv_data(cfg, kv_path) do
    case read_kv(cfg, kv_path) do
      {:ok, %{"data" => %{"data" => data}}} -> {:ok, data}
      resp -> resp
    end
  end
end
