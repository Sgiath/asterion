defmodule Asterion.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :asterion,
      version: @version,

      # Elixir
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "Asterion",
      source_url: "https://github.com/Sgiath/asterion",
      homepage_url: "",
      description: """
      Asterion archive conversion to Obsidian
      """,
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # XLSX file parsing
      {:xlsxir, "~> 1.6"}
    ]
  end

  defp package do
    [
      name: "asterion",
      maintainers: ["Sgiath <asterion@sgiath.dev>"],
      files: ~w(lib LICENSE mix.exs README* CHANGELOG* priv/*),
      licenses: ["WTFPL"],
      links: %{
        "GitHub" => "https://github.com/Sgiath/asterion",
        "Asterion Homepage" => "https://asterionrpg.cz/",
        "Asterion Wiki" => "https://asterion.fandom.com/cs/wiki/Asterion_Wiki"
      }
    ]
  end

  defp docs do
    [
      authors: ["sgiath <asterion@sgiath.dev>"],
      main: "readme",
      api_reference: false,
      extras: [
        "README.md": [filename: "readme", title: "Overview"],
        "CHANGELOG.md": [filename: "changelog", title: "Changelog"]
      ],
      formatters: ["html"],
      source_ref: "v#{@version}",
      source_url: "https://github.com/Sgiath/asterion"
    ]
  end
end
