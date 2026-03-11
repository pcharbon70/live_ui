defmodule LiveUi.Assets do
  @moduledoc """
  Host-facing asset manifest for JavaScript hooks and theme assets used by advanced widgets.
  """

  @javascript_asset_root Path.expand("../../assets/js", __DIR__)
  @javascript_entrypoint "live_ui"
  @javascript_import_path "../../deps/live_ui/assets/js/live_ui"
  @stylesheet_asset_root Path.expand("../../assets/css", __DIR__)
  @stylesheet_entrypoint "live_ui.css"
  @stylesheet_import_path "../../deps/live_ui/assets/css/live_ui.css"

  @hooks %{
    "canvas" => "LiveUi.Canvas",
    "command_palette" => "LiveUi.CommandPalette",
    "split_pane" => "LiveUi.SplitPane",
    "viewport" => "LiveUi.Viewport"
  }

  @spec hooks() :: %{required(String.t()) => String.t()}
  def hooks, do: @hooks

  @spec hook_name(String.t() | atom()) :: String.t() | nil
  def hook_name(kind) do
    Map.get(@hooks, normalize_kind(kind))
  end

  @spec javascript_entrypoint() :: String.t()
  def javascript_entrypoint, do: @javascript_entrypoint

  @spec javascript_entrypoint_path() :: String.t()
  def javascript_entrypoint_path,
    do: Path.join(@javascript_asset_root, "#{@javascript_entrypoint}.js")

  @spec javascript_import_path() :: String.t()
  def javascript_import_path, do: @javascript_import_path

  @spec stylesheet_entrypoint() :: String.t()
  def stylesheet_entrypoint, do: @stylesheet_entrypoint

  @spec stylesheet_entrypoint_path() :: String.t()
  def stylesheet_entrypoint_path, do: Path.join(@stylesheet_asset_root, @stylesheet_entrypoint)

  @spec stylesheet_import_path() :: String.t()
  def stylesheet_import_path, do: @stylesheet_import_path

  defp normalize_kind(kind) when is_atom(kind), do: kind |> Atom.to_string() |> normalize_kind()
  defp normalize_kind(kind) when is_binary(kind), do: kind |> String.trim() |> String.downcase()
  defp normalize_kind(_kind), do: ""
end
