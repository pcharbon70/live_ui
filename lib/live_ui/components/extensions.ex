defmodule LiveUi.Components.Extensions do
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
    <section id={@id} class={["live-ui-extension", "live-ui-extension--#{@kind}" | @classes]} data-live-ui-hook={@hook}>
      <header><%= heading(@kind) %></header>
      <div data-live-ui-state={inspect(Map.take(@props, ["active_tab", "open", "selected", "viewport", "sizes"]))}>
        <%= inspect(@props, pretty: true) %>
      </div>
    </section>
    """
  end

  defp heading(kind), do: kind |> to_string() |> String.replace("_", " ")
end
