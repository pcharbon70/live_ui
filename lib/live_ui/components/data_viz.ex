defmodule LiveUi.Components.DataViz do
  @moduledoc false

  use Phoenix.Component

  alias LiveUi.Assets
  alias LiveUi.Style.Compiler

  attr(:descriptor, :map, required: true)

  def render(assigns) do
    descriptor = assigns.descriptor
    props = Map.get(descriptor, :props, Map.get(descriptor, "props", %{}))

    assigns =
      assigns
      |> assign(:id, Map.get(descriptor, :id, Map.get(descriptor, "id")))
      |> assign(:kind, Map.get(descriptor, :kind, Map.get(descriptor, "kind")))
      |> assign(:props, props)
      |> assign(:classes, Compiler.compile(Map.get(props, "style", %{})))
      |> assign(:hook, Assets.hook_name(Map.get(descriptor, :kind, Map.get(descriptor, "kind"))))

    ~H"""
    <%= if @kind == "canvas" do %>
      <figure id={@id} class={["live-ui-canvas" | @classes]} data-live-ui-hook={@hook}>
        <figcaption><%= value(@props, "title") || "Canvas" %></figcaption>
        <pre><%= inspect(value(@props, "operations"), pretty: true) %></pre>
      </figure>
    <% else %>
      <figure id={@id} class={["live-ui-chart" | @classes]}>
        <figcaption><%= value(@props, "title") || "Chart" %></figcaption>
        <svg viewBox="0 0 100 20" role="img" aria-label={value(@props, "title") || "Chart"}>
          <polyline points={polyline_points(value(@props, "series"))} fill="none" stroke="currentColor" />
        </svg>
      </figure>
    <% end %>
    """
  end

  defp polyline_points(series) when is_list(series) do
    series
    |> Enum.with_index()
    |> Enum.map_join(" ", fn {value, index} -> "#{index * 20},#{20 - normalize_number(value)}" end)
  end

  defp polyline_points(_series), do: "0,20 100,20"

  defp normalize_number(value) when is_integer(value), do: min(max(value, 0), 20)
  defp normalize_number(value) when is_float(value), do: value |> round() |> normalize_number()
  defp normalize_number(_value), do: 0

  defp value(map, key) do
    atom_key =
      case key do
        "operations" -> :operations
        "series" -> :series
        "style" -> :style
        "title" -> :title
        _ -> nil
      end

    Map.get(map, key, if(atom_key, do: Map.get(map, atom_key), else: nil))
  end
end
