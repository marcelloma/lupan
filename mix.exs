defmodule Lupan.MixProject do
  use Mix.Project

  def project do
    [
      app: :lupan,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Lupan.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:crawly, "~> 0.13.0"},
      {:floki, "~> 0.26.0"},
      {:gen_stage, "~> 1.0"},
      {:httpoison, "~> 1.8"},
      {:castore, "~> 0.1.0"},
      {:mint, "~> 1.0"}
    ]
  end
end
