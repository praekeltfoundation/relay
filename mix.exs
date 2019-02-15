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
      # We still want to use the pre-release code because the API has taken a
      # slightly different direction from the last working release
      # (0.3.0-alpha.1) and we want to keep up.
      {
        :grpc,
        git: "https://github.com/tony612/grpc-elixir.git",
        ref: "936f5362bb1f16e671d368605f0195328d16e441"
      },
      {:google_protos, "~> 0.1"},
      {:httpoison, "~> 1.0"},
      # Hackney is a dependency of HTTPoison but had a bug in versions 1.10.0 to
      # 1.12.0 that caused deadlocks with async requests.
      {:hackney, ">= 1.12.1"},
      {:jason, "~> 1.0"},
      {:plug, "~> 1.7"},
      {:plug_cowboy, "~> 2.0"},
      {:cowboy, "~> 2.3"},
      {:exvault, "~> 0.1.0-beta.1"},

      # Test deps.
      {:uuid, "~> 1.1", only: :test},
      {:temp, "~> 0.4", only: :test},
      {:excoveralls, "~> 0.8", only: :test},
      {:vaultdevserver, "~> 0.1", only: [:dev, :test]},

      # Dev/test/build tools.
      {:dialyxir, "~> 1.0.0-rc.3", only: :dev, runtime: false},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:distillery, "~> 2.0", runtime: false}
    ]
  end

  defp dialyzer do
    [
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
