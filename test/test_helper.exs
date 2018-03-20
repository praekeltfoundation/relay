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

  @doc """
  Start some applications for the duration of a test.

  Best used in `setup` or `setup_all` callbacks.
  """
  def setup_apps(apps) do
    started_apps =
      apps
      |> Stream.map(&start_app/1)
      |> Enum.concat()
    on_exit(fn() -> cleanup_apps(started_apps) end)
  end

  defp start_app(app) do
    {:ok, started} = Application.ensure_all_started(app)
    started
  end

  defp cleanup_apps(apps) do
    import ExUnit.CaptureLog
    capture_log(fn() -> apps |> Enum.each(&Application.stop/1) end)
  end

  @doc """
  Set an application configuration option for the duration of the test.
  """
  def swap_env(app, key, new_value) do
    original = Application.get_env(app, key)
    Application.put_env(app, key, new_value)
    on_exit(fn -> Application.put_env(app, key, original) end)

    original
  end
end

ExUnit.start()
