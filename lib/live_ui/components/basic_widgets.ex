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
    button_attrs = Helpers.event_attrs("click", descriptor, click_binding)

    input_event_attrs =
      Helpers.merge_attrs([
        Helpers.event_attrs("change", descriptor, change_binding),
        Helpers.event_attrs("blur", "submit", descriptor, submit_binding)
      ])

    assigns =
      assigns
      |> assign(:id, Helpers.id(descriptor))
      |> assign(:kind, Helpers.kind(descriptor))
      |> assign(:props, props)
      |> assign(:visible, Helpers.visible?(descriptor))
      |> assign(:classes, Helpers.classes(descriptor))
      |> assign(:style, Helpers.inline_style(descriptor))
      |> assign(:button_attrs, button_attrs)
      |> assign(:input_event_attrs, input_event_attrs)

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
            {@button_attrs}
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
            {@input_event_attrs}
          />
        <% _ -> %>
          <div id={@id} class={["live-ui-unknown" | @classes]} style={@style}><%= inspect(@props) %></div>
      <% end %>
    <% end %>
    """
  end

  def text(assigns) do
    direct_render(assigns, "text", %{
      "content" => Map.get(assigns, :content, Map.get(assigns, "content")),
      "text" => Map.get(assigns, :text, Map.get(assigns, "text"))
    })
  end

  def label(assigns) do
    direct_render(assigns, "label", %{
      "for" => Map.get(assigns, :for, Map.get(assigns, "for")),
      "text" => Map.get(assigns, :text, Map.get(assigns, "text"))
    })
  end

  def button(assigns) do
    direct_render(assigns, "button", %{
      "disabled" => Map.get(assigns, :disabled, Map.get(assigns, "disabled")),
      "label" => Map.get(assigns, :label, Map.get(assigns, "label")),
      "text" => Map.get(assigns, :text, Map.get(assigns, "text"))
    })
  end

  def text_input(assigns) do
    direct_render(assigns, "text_input", %{
      "disabled" => Map.get(assigns, :disabled, Map.get(assigns, "disabled")),
      "input_type" => Map.get(assigns, :input_type, Map.get(assigns, "input_type")),
      "placeholder" => Map.get(assigns, :placeholder, Map.get(assigns, "placeholder")),
      "type" => Map.get(assigns, :type, Map.get(assigns, "type")),
      "value" => Map.get(assigns, :value, Map.get(assigns, "value"))
    })
  end

  defp value(map, key, default \\ nil) do
    atom_key = String.to_atom(key)
    Map.get(map, key, Map.get(map, atom_key, default))
  end

  defp truthy?(value) when value in [true, "true", 1, "1"], do: true
  defp truthy?(_value), do: false

  defp direct_render(assigns, kind, extra_props) do
    descriptor = %{
      id: Map.get(assigns, :id, Map.get(assigns, "id")),
      kind: kind,
      props:
        extra_props
        |> Map.merge(%{
          "style" => merged_style(assigns),
          "visible" => Map.get(assigns, :visible, Map.get(assigns, "visible", true))
        })
        |> Enum.reject(fn {_key, value} -> is_nil(value) end)
        |> Map.new(),
      signal_bindings: Map.get(assigns, :signal_bindings, Map.get(assigns, "signal_bindings", []))
    }

    assigns = assign(assigns, :descriptor, descriptor)

    ~H"""
    <.render descriptor={@descriptor} />
    """
  end

  defp merged_style(assigns) do
    style = Map.get(assigns, :style, Map.get(assigns, "style", %{}))
    class_name = Map.get(assigns, :class, Map.get(assigns, "class"))

    case normalize_class_name(class_name) do
      nil ->
        style

      class_name ->
        existing = Map.get(style, "class", Map.get(style, :class))

        Map.put(
          style,
          "class",
          Enum.join(Enum.reject([existing, class_name], &(&1 in [nil, ""])), " ")
        )
    end
  end

  defp normalize_class_name(nil), do: nil
  defp normalize_class_name(""), do: nil
  defp normalize_class_name(class_name) when is_binary(class_name), do: class_name
  defp normalize_class_name(class_name) when is_list(class_name), do: Enum.join(class_name, " ")
  defp normalize_class_name(class_name), do: to_string(class_name)
end
