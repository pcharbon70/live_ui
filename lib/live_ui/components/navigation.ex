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
      |> assign(
        :menu_item_attrs,
        Helpers.event_attrs("click", descriptor, action_binding(descriptor))
      )
      |> assign(
        :command_attrs,
        Helpers.event_attrs("click", descriptor, action_binding(descriptor))
      )
      |> assign(:tree_binding, Helpers.binding(descriptor, ["on_select", "on_toggle"]))
      |> assign(
        :palette_form_attrs,
        Helpers.merge_attrs([
          Helpers.event_attrs("change", descriptor, Helpers.binding(descriptor, "on_change")),
          Helpers.event_attrs(
            "submit",
            descriptor,
            Helpers.binding(descriptor, ["on_submit", "action"])
          )
        ])
      )
      |> assign(
        :palette_hook_attrs,
        Helpers.hook_event_attrs(
          "change",
          descriptor,
          Helpers.binding(descriptor, "on_change"),
          %{
            "active_command_id" => Map.get(props, "active_command_id"),
            "open" => Map.get(props, "open", true)
          }
        )
      )

    ~H"""
    <%= if Helpers.visible?(@descriptor) do %>
      <%= case @kind do %>
        <% "menu_item" -> %>
          <li id={@id} class={@classes}>
            <button type="button" disabled={Helpers.truthy?(Map.get(@props, "disabled", false))} {@menu_item_attrs}>
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
                <% tab_attrs =
                  Helpers.event_attrs(
                    "click",
                    nil,
                    @descriptor,
                    Helpers.binding(@descriptor, "on_change"),
                    %{"tab_id" => Helpers.id(tab)}
                  ) %>
                <button
                  type="button"
                  class={["live-ui-tabs__tab", if(Helpers.id(tab) == active_tab(@props, @children), do: "is-active")]}
                  {tab_attrs ++ [{"phx-value-event_click_tab_index", to_string(tab_index(tab, @children))}]}
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
            <button
              type="button"
              {Helpers.event_attrs(
                "click",
                nil,
                @descriptor,
                @tree_binding,
                %{
                  "expanded" => Helpers.truthy?(Map.get(@props, "expanded", false)),
                  "node_id" => @id
                }
              )}
            >
              <%= Map.get(@props, "label", @id) %>
            </button>
            <%= if Helpers.truthy?(Map.get(@props, "expanded", false)) and @children != [] do %>
              <ul><%= for child <- @children do %><LiveUi.WidgetRegistry.render descriptor={child} /><% end %></ul>
            <% end %>
          </li>
        <% "tree_view" -> %>
          <section id={@id} class={@classes} style={@style}><ul><%= for child <- @children do %><LiveUi.WidgetRegistry.render descriptor={child} /><% end %></ul></section>
        <% "command" -> %>
          <button id={@id} type="button" class={@classes} {@command_attrs}><%= Map.get(@props, "label", "Command") %></button>
        <% "command_palette" -> %>
          <section id={@id} class={@classes} style={@style} data-live-ui-hook={@hook} {@palette_hook_attrs}>
            <form class="live-ui-command-palette__form" {@palette_form_attrs}>
              <input
                type="search"
                name="query"
                value={Map.get(@props, "query", "")}
                placeholder={Map.get(@props, "placeholder", "Search commands")}
              />
            </form>
            <ul data-active-command-id={Map.get(@props, "active_command_id")}>
              <%= for child <- @children do %><LiveUi.WidgetRegistry.render descriptor={child} /><% end %></ul>
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

  defp tab_index(tab, children) do
    Enum.find_index(children, fn child -> Helpers.id(child) == Helpers.id(tab) end) || 0
  end

  defp action_binding(descriptor), do: Helpers.binding(descriptor, ["action", "on_select"])
end
