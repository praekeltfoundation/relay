defmodule Relay.MixProject do
  use Mix.Project

  def project do
    [
      app: :relay,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Relay, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:grpc, github: "tony612/grpc-elixir"},
      # lager_logger stops the Eternal Logging System War.
      {:lager_logger, "~> 1.0"},
      # chatterbox (through grpc) specifies lager from github, which conflicts
      # with version lager_logger wants. Overriding both of them fixes that.
      {:lager, ">= 3.2.4", override: true},
    ]
  end
end
