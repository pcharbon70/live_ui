defmodule LiveUi.Components.Navigation do
  @moduledoc false

  use Phoenix.Component

  alias LiveUi.Components.Helpers

  attr(:descriptor, :map, required: true)

  def render(assigns) do
    descriptor = assigns.descriptor
    props = Helpers.props(descriptor)
    children = Helpers.children(descriptor)
    kind = Helpers.kind(descriptor)

    assigns =
      assigns
      |> assign(:id, Helpers.id(descriptor))
      |> assign(:kind, kind)
      |> assign(:props, props)
      |> assign(:children, children)
      |> assign(
        :classes,
        Helpers.classes(descriptor, ["live-ui-navigation", "live-ui-navigation--#{kind}"])
      )
      |> assign(:style, Helpers.inline_style(descriptor))
      |> assign(:hook, Helpers.hook_name(descriptor))

    ~H"""
    <%= if Helpers.visible?(@descriptor) do %>
      <%= case @kind do %>
        <% "menu_item" -> %>
          <li id={@id} class={@classes}>
            <button type="button" phx-click="click" phx-value-widget_id={@id} phx-value-widget_kind={@kind} phx-value-intent={action_intent(@descriptor)} disabled={Helpers.truthy?(Map.get(@props, "disabled", false))}>
              <%= Map.get(@props, "label", "Item") %>
            </button>
            <%= if @children != [] do %>
              <ul><%= for child <- @children do %><LiveUi.WidgetRegistry.render descriptor={child} /><% end %></ul>
            <% end %>
          </li>
        <% "menu" -> %>
          <nav id={@id} class={@classes} style={@style}><ul><%= for child <- @children do %><LiveUi.WidgetRegistry.render descriptor={child} /><% end %></ul></nav>
        <% "context_menu" -> %>
          <div id={@id} class={@classes} style={@style}><ul><%= for child <- @children do %><LiveUi.WidgetRegistry.render descriptor={child} /><% end %></ul></div>
        <% "tab" -> %>
          <button id={@id} type="button" class={@classes} disabled={Helpers.truthy?(Map.get(@props, "disabled", false))}><%= Map.get(@props, "label", "Tab") %></button>
        <% "tabs" -> %>
          <section id={@id} class={@classes} style={@style}>
            <div class="live-ui-tabs__bar">
              <%= for tab <- @children do %>
                <button
                  type="button"
                  class={["live-ui-tabs__tab", if(Helpers.id(tab) == active_tab(@props, @children), do: "is-active")]}
                  phx-click="click"
                  phx-value-widget_id={@id}
                  phx-value-widget_kind={@kind}
                  phx-value-intent={tabs_intent(@descriptor)}
                  phx-value-tab_id={Helpers.id(tab)}
                >
                  <%= Map.get(Helpers.props(tab), "label", Helpers.id(tab)) %>
                </button>
              <% end %>
            </div>
            <div class="live-ui-tabs__content">
              <LiveUi.WidgetRegistry.render descriptor={active_tab_descriptor(@children, active_tab(@props, @children))} />
            </div>
          </section>
        <% "tree_node" -> %>
          <li id={@id} class={@classes}>
            <button type="button" phx-click="click" phx-value-widget_id={@id} phx-value-widget_kind={@kind} phx-value-intent={tree_intent(@descriptor)}>
              <%= Map.get(@props, "label", @id) %>
            </button>
            <%= if Helpers.truthy?(Map.get(@props, "expanded", false)) and @children != [] do %>
              <ul><%= for child <- @children do %><LiveUi.WidgetRegistry.render descriptor={child} /><% end %></ul>
            <% end %>
          </li>
        <% "tree_view" -> %>
          <section id={@id} class={@classes} style={@style}><ul><%= for child <- @children do %><LiveUi.WidgetRegistry.render descriptor={child} /><% end %></ul></section>
        <% "command" -> %>
          <button id={@id} type="button" class={@classes}><%= Map.get(@props, "label", "Command") %></button>
        <% "command_palette" -> %>
          <section id={@id} class={@classes} style={@style} data-live-ui-hook={@hook}>
            <input type="search" placeholder={Map.get(@props, "placeholder", "Search commands")} />
            <ul><%= for child <- @children do %><LiveUi.WidgetRegistry.render descriptor={child} /><% end %></ul>
          </section>
      <% end %>
    <% end %>
    """
  end

  defp active_tab(props, children) do
    Map.get(props, "active_tab") ||
      children
      |> List.first()
      |> case do
        nil -> nil
        child -> Helpers.id(child)
      end
  end

  defp active_tab_descriptor(children, active_id) do
    Enum.find(children, fn child -> Helpers.id(child) == active_id end)
  end

  defp action_intent(descriptor),
    do: descriptor |> Helpers.binding(["action", "on_select"]) |> Helpers.intent("activate")

  defp tabs_intent(descriptor),
    do: descriptor |> Helpers.binding("on_change") |> Helpers.intent("change")

  defp tree_intent(descriptor),
    do: descriptor |> Helpers.binding(["on_select", "on_toggle"]) |> Helpers.intent("select")
end
