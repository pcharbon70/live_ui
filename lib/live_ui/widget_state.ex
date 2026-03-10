defmodule LiveUi.WidgetState do
  @moduledoc """
  Server-authoritative widget-local state overlay applied after interpretation.
  """

  alias LiveUi.Descriptor

  @spec merge(map(), map() | nil) :: map()
  def merge(current, incoming)

  def merge(current, nil) when is_map(current), do: current

  def merge(current, incoming) when is_map(current) and is_map(incoming) do
    Map.merge(current, incoming, fn _key, left, right ->
      if is_map(left) and is_map(right), do: merge(left, right), else: right
    end)
  end

  @spec extract(map()) :: map()
  def extract(payload) when is_map(payload) do
    case Map.get(payload, "widget_state", Map.get(payload, :widget_state)) do
      %{} = widget_state -> normalize_widget_state(widget_state)
      _ -> %{}
    end
  end

  @spec apply_overlay(Descriptor.t() | nil, map()) :: Descriptor.t() | nil
  def apply_overlay(nil, _widget_state), do: nil

  def apply_overlay(%Descriptor{} = descriptor, widget_state) when is_map(widget_state) do
    merged_props =
      case Map.get(widget_state, descriptor.id) do
        %{} = local_state -> Map.merge(descriptor.props, local_state)
        _ -> descriptor.props
      end

    %Descriptor{
      descriptor
      | props: merged_props,
        children: Enum.map(descriptor.children, &apply_overlay(&1, widget_state))
    }
  end

  defp normalize_widget_state(widget_state) do
    Enum.into(widget_state, %{}, fn {widget_id, state} ->
      {normalize_widget_id(widget_id), normalize_state_map(state)}
    end)
  end

  defp normalize_widget_id(widget_id) when is_atom(widget_id), do: Atom.to_string(widget_id)
  defp normalize_widget_id(widget_id) when is_binary(widget_id), do: widget_id
  defp normalize_widget_id(widget_id), do: to_string(widget_id)

  defp normalize_state_map(%{} = state) do
    Enum.into(state, %{}, fn {key, value} -> {normalize_widget_id(key), value} end)
  end

  defp normalize_state_map(other), do: %{"value" => other}
end
