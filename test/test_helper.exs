defmodule TestHelpers do
  import ExUnit.Callbacks

  @doc """
  Override the global log level for the duration of a test.

  Best used in `setup` or `setup_all` callbacks.
  """
  def override_log_level(level) do
    require Logger
    old_level = Logger.level()
    Logger.configure(level: level)
    on_exit(fn() -> Logger.configure(level: old_level) end)
  end

end

ExUnit.start()
