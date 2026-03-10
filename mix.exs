defmodule LiveUi.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_ui,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:jido_signal, "~> 1.0"},
      {:spec_led_ex,
       git: "https://github.com/specleddev/specled_ex.git", only: [:dev, :test], runtime: false},
      {:phoenix_live_view, "~> 1.0"},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    LiveView adapter and runtime shell for UnifiedUi screens and canonical UnifiedIUR sources.
    """
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "docs/architecture.md", "docs/spec-governance.md"]
    ]
  end

  defp package do
    [
      name: "live_ui",
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/pcharbon70/live_ui"
      }
    ]
  end
end
