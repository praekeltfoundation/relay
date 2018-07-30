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
        coveralls: :test,
        "coveralls.json": :test,
        "coveralls.detail": :test,
        credo: :test,
        release: :prod
      ],
      dialyzer: dialyzer(),
      elixirc_paths: ["lib", "gen"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Relay, []},
      extra_applications: [:logger]
    ]
  end

  defp aliases do
    [
      # Don't start application for tests.
      test: "test --no-start"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # 2018-06-26: grpc-elixir 0.3.0-alpha.2 has an issue that prevents us
      # from sending messages to our servers. It's been fixed on master:
      # https://github.com/tony612/grpc-elixir/issues/59
      #
      # Another issue prevents us from using the current latest git commit :-/
      # https://github.com/tony612/grpc-elixir/issues/67
      #
      # We still want to use the pre-release code because the API has taken a
      # slightly different direction from the last working release
      # (0.3.0-alpha.1) and we want to keep up.
      {
        :grpc,
        git: "https://github.com/tony612/grpc-elixir.git",
        ref: "fce2dea02fb8be815cc5f47ab4cc240132261533"
      },
      # As of the above commit, grpc uses cowlib from git for the 2.4.0 tag
      # which is now available on Hex. Prefer Hex.
      {:cowlib, "~> 2.4", override: true},
      {:google_protos, "~> 0.1"},
      {:httpoison, "~> 1.0"},
      # Hackney is a dependency of HTTPoison but had a bug in versions 1.10.0 to
      # 1.12.0 that caused deadlocks with async requests.
      {:hackney, ">= 1.12.1"},
      {:jason, "~> 1.0"},
      {:conform, "~> 2.2"},
      {:plug, "~> 1.4"},
      {:cowboy, "~> 2.3"},

      # Test deps.
      {
        :sse_test_server,
        git: "https://github.com/praekeltfoundation/sse_test_server.git",
        ref: "2a3f83892020a6861464644ee8014d20b188fac0",
        only: :test,
        app: false
      },
      {:uuid, "~> 1.1", only: :test},
      {:temp, "~> 0.4", only: :test},
      {:excoveralls, "~> 0.8", only: :test},

      # Dev/test/build tools.
      {:dialyxir, "~> 1.0.0-rc.3", only: :dev, runtime: false},
      {:credo, "~> 0.9", only: [:dev, :test], runtime: false},
      {:distillery, "~> 1.5", runtime: false}
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
        :underspecs
      ]
    ]
  end
end
