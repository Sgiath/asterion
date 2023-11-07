defmodule Mix.Tasks.Convert do
  @moduledoc "Convert XLSX Asterion archive to Markdown files"
  @shortdoc "Convert archive"

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Application.ensure_all_started(:asterion)
    Asterion.load_all()

    Mix.shell().cmd("cd priv/export/ && zip -r ../../asterion.zip *")
  end
end
