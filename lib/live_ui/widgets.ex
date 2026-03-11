defmodule LiveUi.Widgets do
  @moduledoc """
  Public widget and layout components for composing `live_ui` screens directly.

  These components use the same renderer families as the `UnifiedIUR` path so
  direct composition and interpreted rendering stay aligned.
  """

  use Phoenix.Component

  alias LiveUi.Components.BasicWidgets
  alias LiveUi.Components.Layouts
  alias LiveUi.WidgetRegistry

  attr(:descriptor, :map, required: true)

  def render(assigns) do
    ~H"""
    <WidgetRegistry.render descriptor={@descriptor} />
    """
  end

  attr(:id, :string, default: nil)
  attr(:style, :map, default: %{})
  attr(:class, :any, default: nil)
  attr(:visible, :boolean, default: true)
  attr(:content, :string, default: nil)
  attr(:text, :string, default: nil)
  attr(:signal_bindings, :list, default: [])
  def text(assigns), do: BasicWidgets.text(assigns)

  attr(:id, :string, default: nil)
  attr(:style, :map, default: %{})
  attr(:class, :any, default: nil)
  attr(:visible, :boolean, default: true)
  attr(:for, :string, default: nil)
  attr(:text, :string, default: nil)
  def label(assigns), do: BasicWidgets.label(assigns)

  attr(:id, :string, default: nil)
  attr(:style, :map, default: %{})
  attr(:class, :any, default: nil)
  attr(:visible, :boolean, default: true)
  attr(:label, :string, default: nil)
  attr(:text, :string, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:signal_bindings, :list, default: [])
  def button(assigns), do: BasicWidgets.button(assigns)

  attr(:id, :string, default: nil)
  attr(:style, :map, default: %{})
  attr(:class, :any, default: nil)
  attr(:visible, :boolean, default: true)
  attr(:value, :string, default: nil)
  attr(:placeholder, :string, default: nil)
  attr(:type, :string, default: nil)
  attr(:input_type, :string, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:signal_bindings, :list, default: [])
  def text_input(assigns), do: BasicWidgets.text_input(assigns)

  attr(:id, :string, default: nil)
  attr(:style, :map, default: %{})
  attr(:class, :any, default: nil)
  attr(:visible, :boolean, default: true)
  attr(:spacing, :any, default: nil)
  attr(:gap, :any, default: nil)
  attr(:padding, :any, default: nil)
  attr(:align_items, :string, default: nil)
  attr(:justify_content, :string, default: nil)
  attr(:signal_bindings, :list, default: [])
  slot(:inner_block)
  def vbox(assigns), do: Layouts.vbox(assigns)

  attr(:id, :string, default: nil)
  attr(:style, :map, default: %{})
  attr(:class, :any, default: nil)
  attr(:visible, :boolean, default: true)
  attr(:spacing, :any, default: nil)
  attr(:gap, :any, default: nil)
  attr(:padding, :any, default: nil)
  attr(:align_items, :string, default: nil)
  attr(:justify_content, :string, default: nil)
  attr(:signal_bindings, :list, default: [])
  slot(:inner_block)
  def hbox(assigns), do: Layouts.hbox(assigns)

  attr(:id, :string, default: nil)
  attr(:style, :map, default: %{})
  attr(:class, :any, default: nil)
  attr(:visible, :boolean, default: true)
  attr(:gap, :any, default: nil)
  attr(:padding, :any, default: nil)
  attr(:columns, :list, default: nil)
  attr(:rows, :list, default: nil)
  attr(:signal_bindings, :list, default: [])
  slot(:inner_block)
  def grid(assigns), do: Layouts.grid(assigns)

  attr(:id, :string, default: nil)
  attr(:style, :map, default: %{})
  attr(:class, :any, default: nil)
  attr(:visible, :boolean, default: true)
  attr(:active_index, :any, default: 0)
  attr(:signal_bindings, :list, default: [])
  slot(:panel)
  def stack(assigns), do: Layouts.stack(assigns)

  attr(:id, :string, default: nil)
  attr(:style, :map, default: %{})
  attr(:class, :any, default: nil)
  attr(:visible, :boolean, default: true)
  attr(:positions, :map, default: %{})
  attr(:signal_bindings, :list, default: [])
  slot(:layer)
  def zbox(assigns), do: Layouts.zbox(assigns)

  attr(:id, :string, default: nil)
  attr(:style, :map, default: %{})
  attr(:class, :any, default: nil)
  attr(:visible, :boolean, default: true)
  attr(:axis, :string, default: nil)
  attr(:scroll_top, :any, default: 0)
  attr(:scroll_left, :any, default: 0)
  attr(:signal_bindings, :list, default: [])
  slot(:inner_block)
  def viewport(assigns), do: Layouts.viewport(assigns)

  attr(:id, :string, default: nil)
  attr(:style, :map, default: %{})
  attr(:class, :any, default: nil)
  attr(:visible, :boolean, default: true)
  attr(:gap, :any, default: nil)
  attr(:padding, :any, default: nil)
  attr(:sizes, :list, default: nil)
  attr(:initial_split, :any, default: nil)
  attr(:orientation, :string, default: nil)
  attr(:signal_bindings, :list, default: [])
  slot(:pane)
  def split_pane(assigns), do: Layouts.split_pane(assigns)
end
