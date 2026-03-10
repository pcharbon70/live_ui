defmodule LiveUi.Components.Extensions do
  @moduledoc false

  use Phoenix.Component

  alias LiveUi.Components.Helpers

  attr(:descriptor, :map, required: true)

  def render(assigns) do
    descriptor = assigns.descriptor
    props = Helpers.props(descriptor)

    assigns =
      assigns
      |> assign(:id, Helpers.id(descriptor))
      |> assign(:kind, Helpers.kind(descriptor))
      |> assign(:props, props)
      |> assign(
        :classes,
        Helpers.classes(descriptor, [
          "live-ui-extension",
          "live-ui-extension--#{Helpers.kind(descriptor)}"
        ])
      )
      |> assign(:style, Helpers.inline_style(descriptor))
      |> assign(:hook, Helpers.hook_name(descriptor))

    ~H"""
    <%= if Helpers.visible?(@descriptor) do %>
      <section id={@id} class={@classes} style={@style} data-live-ui-hook={@hook}>
        <header><%= @kind |> to_string() |> String.replace("_", " ") %></header>
        <div data-live-ui-state={inspect(Map.take(@props, ["auto_refresh", "buffer_size", "filter", "lines", "node", "refresh_interval", "source"]))}>
          <%= inspect(@props, pretty: true) %>
        </div>
      </section>
    <% end %>
    """
  end
end
