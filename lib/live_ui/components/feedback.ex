defmodule LiveUi.Components.Feedback do
  @moduledoc false

  use Phoenix.Component

  alias LiveUi.Components.Helpers

  attr(:descriptor, :map, required: true)

  def render(assigns) do
    descriptor = assigns.descriptor
    props = Helpers.props(descriptor)
    children = Helpers.children(descriptor)
    kind = Helpers.kind(descriptor)

    {content_children, action_children} =
      Enum.split_with(children, &(Helpers.kind(&1) != "dialog_button"))

    assigns =
      assigns
      |> assign(:id, Helpers.id(descriptor))
      |> assign(:kind, kind)
      |> assign(:props, props)
      |> assign(:content_children, content_children)
      |> assign(:action_children, action_children)
      |> assign(
        :classes,
        Helpers.classes(descriptor, ["live-ui-feedback", "live-ui-feedback--#{kind}"])
      )
      |> assign(:style, Helpers.inline_style(descriptor))
      |> assign(
        :dialog_button_attrs,
        Helpers.event_attrs("click", descriptor, button_binding(descriptor))
      )
      |> assign(
        :confirm_attrs,
        Helpers.event_attrs("click", descriptor, Helpers.binding(descriptor, "on_confirm"))
      )
      |> assign(
        :cancel_attrs,
        Helpers.event_attrs("click", descriptor, Helpers.binding(descriptor, "on_cancel"))
      )

    ~H"""
    <%= if Helpers.visible?(@descriptor) do %>
      <%= case @kind do %>
        <% "dialog_button" -> %>
          <button id={@id} type="button" class={@classes} {@dialog_button_attrs}>
            <%= Map.get(@props, "label", "Action") %>
          </button>
        <% "dialog" -> %>
          <aside id={@id} class={@classes} style={@style} role="dialog" aria-modal={Helpers.truthy?(Map.get(@props, "modal", true))}>
            <header><h2><%= Map.get(@props, "title", "Dialog") %></h2></header>
            <div class="live-ui-dialog__content"><%= for child <- @content_children do %><LiveUi.WidgetRegistry.render descriptor={child} /><% end %></div>
            <footer><%= for child <- @action_children do %><LiveUi.WidgetRegistry.render descriptor={child} /><% end %></footer>
          </aside>
        <% "alert_dialog" -> %>
          <aside id={@id} class={@classes} style={@style} role="alertdialog">
            <header><h2><%= Map.get(@props, "title", "Alert") %></h2></header>
            <p><%= Map.get(@props, "message", "") %></p>
            <div class="live-ui-alert__actions">
              <button type="button" {@confirm_attrs}>Confirm</button>
              <button type="button" {@cancel_attrs}>Cancel</button>
            </div>
          </aside>
        <% "toast" -> %>
          <aside id={@id} class={@classes} style={@style} role="status">
            <p><%= Map.get(@props, "message", "") %></p>
          </aside>
      <% end %>
    <% end %>
    """
  end

  defp button_binding(descriptor), do: Helpers.binding(descriptor, "action")
end
