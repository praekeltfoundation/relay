defmodule Relay.MixProject do
  use Mix.Project

  def project do
    [
      app: :relay,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      aliases: aliases(),
      preferred_cli_env: [
        "coveralls": :test,
        "coveralls.json": :test,
        "coveralls.detail": :test,
      ],
      dialyzer: dialyzer(),
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Relay, []},
      extra_applications: [:logger]
    ]
  end

  defp aliases, do: [
    # Don't start application for tests.
    test: "test --no-start",
  ]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:grpc, github: "tony612/grpc-elixir"},

      # 2017-12-13: The latest hackney release (1.10.1) has a bug in async
      # request cleanup: https://github.com/benoitc/hackney/issues/447 The
      # partial fix in master leaves us with a silent deadlock, so for now
      # we'll use an earlier version.
      {:hackney, "~> 1.9.0"},
      {:httpoison, "~> 0.13"},

      {:poison, "~> 3.1"},

      # Test deps.
      {:sse_test_server,
       git: "https://github.com/praekeltfoundation/sse_test_server.git",
       ref: "d8917d260685a306834a476a7457469be590c4d4",
       only: :test,
       # We need this installed, but we don't want to run its app.
       app: false},

      {:excoveralls, "~> 0.8", only: :test},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:credo, "~> 0.9.0-rc1", only: [:dev, :test], runtime: false}
    ]
  end

  defp dialyzer do
    [
      # There are some warnings in the generated code that we don't control, so
      # we put them in the ignore file. The exact details of the warnings may
      # change when we regenerate the code, so the ignore file should be
      # updated to match.
      ignore_warnings: "dialyzer.ignore-warnings",
      # These are most of the optional warnings in the dialyzer docs. We skip
      # :error_handling (because we don't care about functions that only raise
      # exceptions) and two others that are intended for developing dialyzer
      # itself.
      flags: [
        :unmatched_returns,
        # The dialyzer docs indicate that the race condition check can
        # sometimes take a whole lot of time.
        :race_conditions,
        :underspecs,
      ],
    ]
  end
end
