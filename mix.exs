defmodule LiveProps.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_props,
      version: "0.2.0",
      description: "Props and State for Phoenix LiveView",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :phoenix]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_live_view, "~> 0.13.2"},
      {:floki, ">= 0.0.0", only: :test},
      {:jason, "~> 1.2", only: [:dev, :test]},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false}
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  def package do
    [
      licenses: ["MIT"],
      links: %{github: "https://github.com/mbreuer23/phoenix-live-props"}
    ]
  end

  defp docs do
    [
      main: "LiveProps",
      source_url: "https://github.com/mbreuer23/phoenix-live-props"
      # extra_section: "GUIDES",
      # extras: extras(),
      # groups_for_extras: groups_for_extras(),
      # groups_for_modules: groups_for_modules()
    ]
  end
end
