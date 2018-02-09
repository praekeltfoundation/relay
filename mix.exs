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
      # https://github.com/tony612/protobuf-elixir/pull/18
      {:protobuf, github: "tony612/protobuf-elixir", override: true},
      # lager_logger stops the Eternal Logging System War.
      {:lager_logger, "~> 1.0"},
      # chatterbox (through grpc) specifies lager from github, which conflicts
      # with version lager_logger wants. Overriding both of them fixes that.
      {:lager, ">= 3.2.4", override: true},

      # 2017-12-13: The latest hackney release (1.10.1) has a bug in async
      # request cleanup: https://github.com/benoitc/hackney/issues/447 The
      # partial fix in master leaves us with a silent deadlock, so for now
      # we'll use an earlier version.
      {:hackney, "~> 1.9.0"},
      {:httpoison, "~> 0.13"},

      # Test deps.
      {:exjsx, "~> 4.0", only: :test},
      {:sse_test_server,
       git: "https://github.com/praekeltfoundation/sse_test_server.git",
       ref: "d4afd19a7ce7aae2f3828eb07f3cfd73a00fa2a1",
       only: :test,
       # We need this installed, but we don't want to run its app.
       app: false},
    ]
  end
end
