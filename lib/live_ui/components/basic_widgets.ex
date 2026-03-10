defmodule LiveUi.Components.BasicWidgets do
  @moduledoc false

  use Phoenix.Component

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

    ~H"""
    <%= case @kind do %>
      <% "text" -> %>
        <p id={@id} class={["live-ui-text" | @classes]}><%= value(@props, "text") %></p>
      <% "label" -> %>
        <label id={@id} class={["live-ui-label" | @classes]}><%= value(@props, "text") %></label>
      <% "button" -> %>
        <button id={@id} type="button" class={["live-ui-button" | @classes]}><%= value(@props, "label", value(@props, "text")) %></button>
      <% "text_input" -> %>
        <input id={@id} type="text" class={["live-ui-input" | @classes]} value={value(@props, "value", "")} />
      <% _ -> %>
        <div id={@id} class={["live-ui-unknown" | @classes]}><%= inspect(@props) %></div>
    <% end %>
    """
  end

  defp value(map, key, default \\ nil) do
    atom_key =
      case key do
        "label" -> :label
        "style" -> :style
        "text" -> :text
        "value" -> :value
        _ -> nil
      end

    Map.get(map, key, if(atom_key, do: Map.get(map, atom_key, default), else: default))
  end
end
