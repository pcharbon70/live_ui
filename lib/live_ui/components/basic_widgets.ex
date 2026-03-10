defmodule LiveUi.Components.BasicWidgets do
  @moduledoc false

  use Phoenix.Component

  alias LiveUi.Components.Helpers

  attr(:descriptor, :map, required: true)

  def render(assigns) do
    descriptor = assigns.descriptor
    props = Helpers.props(descriptor)
    click_binding = Helpers.binding(descriptor, ["on_click", "action"])
    change_binding = Helpers.binding(descriptor, "on_change")
    submit_binding = Helpers.binding(descriptor, "on_submit")

    assigns =
      assigns
      |> assign(:id, Helpers.id(descriptor))
      |> assign(:kind, Helpers.kind(descriptor))
      |> assign(:props, props)
      |> assign(:visible, Helpers.visible?(descriptor))
      |> assign(:classes, Helpers.classes(descriptor))
      |> assign(:style, Helpers.inline_style(descriptor))
      |> assign(:click_intent, Helpers.intent(click_binding, "activate"))
      |> assign(:change_intent, Helpers.intent(change_binding, "change"))
      |> assign(:submit_intent, Helpers.intent(submit_binding, "submit"))

    ~H"""
    <%= if @visible do %>
      <%= case @kind do %>
        <% "text" -> %>
          <p id={@id} class={["live-ui-text" | @classes]} style={@style} data-live-ui-widget-id={@id}>
            <%= value(@props, "content", value(@props, "text", "")) %>
          </p>
        <% "label" -> %>
          <label id={@id} for={value(@props, "for")} class={["live-ui-label" | @classes]} style={@style}>
            <%= value(@props, "text", "") %>
          </label>
        <% "button" -> %>
          <button
            id={@id}
            type="button"
            class={["live-ui-button" | @classes]}
            style={@style}
            disabled={truthy?(value(@props, "disabled", false))}
            phx-click={if @click_intent, do: "click"}
            phx-value-widget_id={@id}
            phx-value-widget_kind={@kind}
            phx-value-intent={@click_intent}
          >
            <%= value(@props, "label", value(@props, "text", "Button")) %>
          </button>
        <% "text_input" -> %>
          <input
            id={@id}
            name={@id}
            type={value(@props, "input_type", value(@props, "type", "text"))}
            class={["live-ui-input" | @classes]}
            style={@style}
            value={value(@props, "value", "")}
            placeholder={value(@props, "placeholder")}
            disabled={truthy?(value(@props, "disabled", false))}
            phx-change={if @change_intent, do: "change"}
            phx-blur={if @submit_intent, do: "submit"}
            phx-value-widget_id={@id}
            phx-value-widget_kind={@kind}
            phx-value-intent={@change_intent}
          />
        <% _ -> %>
          <div id={@id} class={["live-ui-unknown" | @classes]} style={@style}><%= inspect(@props) %></div>
      <% end %>
    <% end %>
    """
  end

  defp value(map, key, default \\ nil) do
    atom_key = String.to_atom(key)
    Map.get(map, key, Map.get(map, atom_key, default))
  end

  defp truthy?(value) when value in [true, "true", 1, "1"], do: true
  defp truthy?(_value), do: false
end
