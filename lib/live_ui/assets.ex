defmodule LiveUi.Assets do
  @moduledoc """
  Host-facing asset manifest for JavaScript hooks used by advanced widgets.
  """

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
  def javascript_entrypoint, do: "live_ui"

  defp normalize_kind(kind) when is_atom(kind), do: kind |> Atom.to_string() |> normalize_kind()
  defp normalize_kind(kind) when is_binary(kind), do: kind |> String.trim() |> String.downcase()
  defp normalize_kind(_kind), do: ""
end
