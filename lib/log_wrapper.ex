defmodule LogWrapper do

  @moduledoc """
  LogWrapper is a wrapper around the `Logger` module that exists solely to
  throw away return values. This gets rid of dialyzer `unmatched_returns`
  warning noise without sprinkling `_ = Logger.whatever` all over our code or
  manually maintaining a bunch of per-line ignore entries.
  """

  defmacro __using__(alias_opts) do
    quote do
      require LogWrapper
      alias LogWrapper, unquote(alias_opts)
    end
  end

  @doc """
  Logs a debug message.

  Always returns `:ok`, blissfully ignoring any logger errors.
  """
  defmacro debug(chardata_or_fun, metadata \\ []) do
    quote do
      require Logger
      _ = Logger.debug(unquote(chardata_or_fun), unquote(metadata))
      :ok
    end
  end

  @doc """
  Logs an info message.

  Always returns `:ok`, blissfully ignoring any logger errors.
  """
  defmacro info(chardata_or_fun, metadata \\ []) do
    quote do
      require Logger
      _ = Logger.info(unquote(chardata_or_fun), unquote(metadata))
      :ok
    end
  end

  @doc """
  Logs a warn message.

  Always returns `:ok`, blissfully ignoring any logger errors.
  """
  defmacro warn(chardata_or_fun, metadata \\ []) do
    quote do
      require Logger
      _ = Logger.warn(unquote(chardata_or_fun), unquote(metadata))
      :ok
    end
  end

  @doc """
  Logs an error message.

  Always returns `:ok`, blissfully ignoring any logger errors.
  """
  defmacro error(chardata_or_fun, metadata \\ []) do
    quote do
      require Logger
      _ = Logger.error(unquote(chardata_or_fun), unquote(metadata))
      :ok
    end
  end
end
