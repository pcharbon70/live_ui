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
      |> assign(:tree_select_binding, Helpers.binding(descriptor, "on_select"))
      |> assign(:tree_toggle_binding, Helpers.binding(descriptor, "on_toggle"))
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
              :if={@tree_toggle_binding}
              type="button"
              class="live-ui-tree__toggle"
              aria-label={if(Helpers.truthy?(Map.get(@props, "expanded", false)), do: "Collapse node", else: "Expand node")}
              {Helpers.event_attrs(
                "click",
                nil,
                @descriptor,
                @tree_toggle_binding,
                tree_toggle_payload(@descriptor, @children)
              )}
            >
              <%= if Helpers.truthy?(Map.get(@props, "expanded", false)), do: "-", else: "+" %>
            </button>
            <button
              type="button"
              class={["live-ui-tree__node", if(Helpers.truthy?(Map.get(@props, "selected", false)), do: "is-selected")]}
              aria-expanded={if(Helpers.truthy?(Map.get(@props, "expanded", false)), do: "true", else: "false")}
              {Helpers.event_attrs(
                "click",
                nil,
                @descriptor,
                tree_primary_binding(@tree_select_binding, @tree_toggle_binding),
                tree_primary_payload(@descriptor, @children, @tree_select_binding)
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
          <section
            id={@id}
            class={[@classes, if(Helpers.truthy?(Map.get(@props, "open", true)), do: "is-open", else: "is-closed")]}
            style={@style}
            data-live-ui-hook={@hook}
            data-open={if(Helpers.truthy?(Map.get(@props, "open", true)), do: "true", else: "false")}
            {@palette_hook_attrs}
          >
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

  defp tree_primary_binding(select_binding, nil), do: select_binding
  defp tree_primary_binding(nil, toggle_binding), do: toggle_binding
  defp tree_primary_binding(select_binding, _toggle_binding), do: select_binding

  defp tree_primary_payload(descriptor, children, select_binding) do
    base = tree_payload(descriptor, children)

    if is_nil(select_binding) do
      Map.put(base, "next_expanded", not Map.fetch!(base, "expanded"))
    else
      Map.put(base, "selected", true)
    end
  end

  defp tree_toggle_payload(descriptor, children) do
    tree_payload(descriptor, children)
    |> Map.put(
      "next_expanded",
      not Helpers.truthy?(Map.get(Helpers.props(descriptor), "expanded", false))
    )
    |> Map.put("selected", false)
  end

  defp tree_payload(descriptor, children) do
    expanded = Helpers.truthy?(Map.get(Helpers.props(descriptor), "expanded", false))

    %{
      "child_count" => length(children),
      "expanded" => expanded,
      "node_id" => Helpers.id(descriptor)
    }
  end
end
