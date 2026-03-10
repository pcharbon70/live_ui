defmodule LiveUi.Components.Forms do
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
        Helpers.classes(descriptor, ["live-ui-forms", "live-ui-forms--#{kind}"])
      )
      |> assign(:style, Helpers.inline_style(descriptor))
      |> assign(
        :pick_list_attrs,
        Helpers.event_attrs("change", descriptor, pick_list_binding(descriptor))
      )
      |> assign(
        :form_attrs,
        Helpers.merge_attrs([
          Helpers.event_attrs("change", descriptor, form_change_binding(descriptor)),
          Helpers.event_attrs("submit", descriptor, form_binding(descriptor))
        ])
      )
      |> assign(:row_select_binding, Helpers.binding(descriptor, "on_row_select"))
      |> assign(:sort_binding, Helpers.binding(descriptor, "on_sort"))

    ~H"""
    <%= if Helpers.visible?(@descriptor) do %>
      <%= case @kind do %>
        <% "pick_list_option" -> %>
          <option value={Map.get(@props, "value")} selected={selected?(@props)}><%= Map.get(@props, "label", Map.get(@props, "value")) %></option>
        <% "pick_list" -> %>
          <div id={@id} class={@classes} style={@style}>
            <select id={@id <> "-select"} name={@id} {@pick_list_attrs}>
              <option :if={Map.get(@props, "placeholder")} value=""><%= Map.get(@props, "placeholder") %></option>
              <%= for child <- @children do %><LiveUi.WidgetRegistry.render descriptor={child} /><% end %>
            </select>
          </div>
        <% "form_field" -> %>
          <div id={@id} class={@classes} style={@style}>
            <label :if={Map.get(@props, "label")}><%= Map.get(@props, "label") %></label>
            <%= field_input(@props) %>
          </div>
        <% "form_builder" -> %>
          <form id={@id} class={@classes} style={@style} {@form_attrs}>
            <%= for child <- @children do %><LiveUi.WidgetRegistry.render descriptor={child} /><% end %>
            <button type="submit"><%= Map.get(@props, "submit_label", "Submit") %></button>
          </form>
        <% "column" -> %>
          <span id={@id} class={@classes}><%= Map.get(@props, "header", Map.get(@props, "key", "column")) %></span>
        <% "table" -> %>
          <table id={@id} class={@classes} style={@style}>
            <thead>
              <tr>
                <%= for column <- table_columns(@props) do %>
                  <% sort_attrs =
                    Helpers.event_attrs(
                      "click",
                      nil,
                      @descriptor,
                      @sort_binding,
                      %{"sort_column" => Map.get(column, "key")}
                    ) %>
                  <th>
                    <button :if={@sort_binding} type="button" {sort_attrs}>
                      <%= Map.get(column, "header", Map.get(column, "key", "")) %>
                    </button>
                    <span :if={is_nil(@sort_binding)}>
                      <%= Map.get(column, "header", Map.get(column, "key", "")) %>
                    </span>
                  </th>
                <% end %>
              </tr>
            </thead>
            <tbody>
              <%= for {row, index} <- Enum.with_index(table_rows(@props)) do %>
                <% row_attrs =
                  Helpers.event_attrs(
                    "click",
                    nil,
                    @descriptor,
                    @row_select_binding,
                    %{
                      "row_id" => table_row_id(row, index),
                      "row_index" => index
                    }
                  ) %>
                <tr {row_attrs}>
                  <%= for column <- table_columns(@props) do %>
                    <td><%= table_cell(row, column) %></td>
                  <% end %>
                </tr>
              <% end %>
            </tbody>
          </table>
      <% end %>
    <% end %>
    """
  end

  defp selected?(props), do: Helpers.truthy?(Map.get(props, "selected", false))

  defp pick_list_binding(descriptor), do: Helpers.binding(descriptor, "on_select")
  defp form_change_binding(descriptor), do: Helpers.binding(descriptor, "on_change")
  defp form_binding(descriptor), do: Helpers.binding(descriptor, ["on_submit", "action"])

  defp table_rows(props), do: Map.get(props, "data", [])
  defp table_columns(props), do: Enum.map(Map.get(props, "columns", []), &normalize_column/1)

  defp normalize_column(%{} = column), do: column
  defp normalize_column(other), do: %{"header" => inspect(other), "key" => inspect(other)}

  defp table_cell(%{} = row, column) do
    key = Map.get(column, "key")
    Map.get(row, key, Map.get(row, String.to_atom(key || ""), ""))
  rescue
    ArgumentError -> ""
  end

  defp table_cell(row, _column), do: inspect(row)

  defp table_row_id(%{} = row, index) do
    Map.get(row, "id", Map.get(row, :id, index))
  end

  defp table_row_id(_row, index), do: index

  defp field_input(props) do
    type = Map.get(props, "field_type", Map.get(props, "type", "text"))
    name = Map.get(props, "name", "field")
    placeholder = Map.get(props, "placeholder")
    default = Map.get(props, "default", "")
    options = Map.get(props, "options", [])
    disabled = Helpers.truthy?(Map.get(props, "disabled", false))

    assigns = %{
      field_type: type,
      name: name,
      placeholder: placeholder,
      default: default,
      options: options,
      disabled: disabled
    }

    ~H"""
    <%= case @field_type do %>
      <% checkbox_type when checkbox_type in ["checkbox", :checkbox] -> %>
        <input type="checkbox" name={Helpers.scalar_string(@name)} checked={Helpers.truthy?(@default)} disabled={@disabled} />
      <% select_type when select_type in ["select", :select] -> %>
        <select name={Helpers.scalar_string(@name)} disabled={@disabled}>
          <%= for option <- @options do %>
            <option value={option_value(option)}><%= option_label(option) %></option>
          <% end %>
        </select>
      <% input_type -> %>
        <input type={Helpers.scalar_string(input_type) || "text"} name={Helpers.scalar_string(@name)} value={Helpers.scalar_string(@default)} placeholder={@placeholder} disabled={@disabled} />
    <% end %>
    """
  end

  defp option_value(%{"value" => value}), do: value
  defp option_value({value, _label}), do: value
  defp option_value(value), do: value

  defp option_label(%{"label" => label}), do: label
  defp option_label({_value, label}), do: label
  defp option_label(value), do: Helpers.scalar_string(value)
end
