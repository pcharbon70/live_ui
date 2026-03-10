defmodule LiveUi.Components.Layouts do
  @moduledoc false

  use Phoenix.Component

  alias LiveUi.Style.Compiler

  attr(:descriptor, :map, required: true)

  def render(assigns) do
    descriptor = assigns.descriptor
    props = Map.get(descriptor, :props, Map.get(descriptor, "props", %{}))
    children = Map.get(descriptor, :children, Map.get(descriptor, "children", []))

    assigns =
      assigns
      |> assign(:id, Map.get(descriptor, :id, Map.get(descriptor, "id")))
      |> assign(:kind, Map.get(descriptor, :kind, Map.get(descriptor, "kind")))
      |> assign(:children, children)
      |> assign(:classes, Compiler.compile(Map.get(props, "style", %{})))

    ~H"""
    <div id={@id} class={["live-ui-layout", "live-ui-layout--#{@kind}" | @classes]}>
      <%= for child <- @children do %>
        <LiveUi.WidgetRegistry.render descriptor={child} />
      <% end %>
    </div>
    """
  end
end
