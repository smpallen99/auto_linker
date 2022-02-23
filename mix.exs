defmodule AutoLinker.Mixfile do
  use Mix.Project

  @version "1.1.0"

  def project do
    [
      app: :auto_linker,
      version: @version,
      elixir: "~> 1.11",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [extras: ["README.md"]],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        test: :test
      ],
      package: package(),
      name: "AutoLinker",
      description: """
      AutoLinker is a basic package for turning website names into links.
      """
    ]
  end

  # Configuration for the OTP application
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev},
      {:earmark, "~> 1.2", only: :dev, override: true},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: :test}
    ]
  end

  defp package do
    [
      maintainers: ["Stephen Pallen"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/smpallen99/auto_linker"},
      files: ~w(lib README.md mix.exs LICENSE)
    ]
  end
end
