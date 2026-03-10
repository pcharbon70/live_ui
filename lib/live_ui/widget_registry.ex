defmodule LiveUi.WidgetRegistry do
  @moduledoc """
  Local widget registry used by the compliance-closing tests and initial renderer skeleton.
  """

  use Phoenix.Component

  alias LiveUi.Components.BasicWidgets
  alias LiveUi.Components.DataViz
  alias LiveUi.Components.Extensions
  alias LiveUi.Components.Layouts

  @kind_to_module %{
    "button" => BasicWidgets,
    "canvas" => DataViz,
    "chart" => DataViz,
    "command_palette" => Extensions,
    "dialog" => Extensions,
    "hbox" => Layouts,
    "label" => BasicWidgets,
    "pick_list" => Extensions,
    "split_pane" => Extensions,
    "table" => Extensions,
    "tabs" => Extensions,
    "text" => BasicWidgets,
    "text_input" => BasicWidgets,
    "toast" => Extensions,
    "tree_view" => Extensions,
    "vbox" => Layouts,
    "viewport" => Extensions
  }

  @spec supported_kinds() :: [String.t()]
  def supported_kinds do
    @kind_to_module |> Map.keys() |> Enum.sort()
  end

  @spec supported_kind?(String.t() | atom()) :: boolean()
  def supported_kind?(kind) do
    Map.has_key?(@kind_to_module, normalize_kind(kind))
  end

  @spec renderer_for(String.t() | atom()) :: {:ok, module()} | :error
  def renderer_for(kind) do
    Map.fetch(@kind_to_module, normalize_kind(kind))
  end

  attr(:descriptor, :map, required: true)

  def render(assigns) do
    descriptor = Map.new(assigns.descriptor)
    kind = normalize_kind(Map.get(descriptor, :kind, Map.get(descriptor, "kind")))
    assigns = assign(assigns, :descriptor, Map.put(descriptor, :kind, kind))

    ~H"""
    <%= case renderer_for(@descriptor.kind) do %>
      <% {:ok, LiveUi.Components.BasicWidgets} -> %>
        <LiveUi.Components.BasicWidgets.render descriptor={@descriptor} />
      <% {:ok, LiveUi.Components.Layouts} -> %>
        <LiveUi.Components.Layouts.render descriptor={@descriptor} />
      <% {:ok, LiveUi.Components.Extensions} -> %>
        <LiveUi.Components.Extensions.render descriptor={@descriptor} />
      <% {:ok, LiveUi.Components.DataViz} -> %>
        <LiveUi.Components.DataViz.render descriptor={@descriptor} />
      <% :error -> %>
        <% raise ConfigurationError.new("unsupported widget kind", %{kind: inspect(@descriptor.kind)}) %>
    <% end %>
    """
  end

  defp normalize_kind(kind) when is_atom(kind), do: kind |> Atom.to_string() |> normalize_kind()
  defp normalize_kind(kind) when is_binary(kind), do: kind |> String.trim() |> String.downcase()
  defp normalize_kind(_kind), do: ""
end
