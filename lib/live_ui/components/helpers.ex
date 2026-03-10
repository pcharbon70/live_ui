defmodule LiveUi.Components.Helpers do
  @moduledoc false

  alias LiveUi.Assets
  alias LiveUi.Style.Compiler

  @spec id(map()) :: String.t() | nil
  def id(descriptor), do: Map.get(descriptor, :id, Map.get(descriptor, "id"))

  @spec kind(map()) :: String.t() | nil
  def kind(descriptor), do: Map.get(descriptor, :kind, Map.get(descriptor, "kind"))

  @spec props(map()) :: map()
  def props(descriptor), do: Map.get(descriptor, :props, Map.get(descriptor, "props", %{}))

  @spec children(map()) :: [map()]
  def children(descriptor),
    do: Map.get(descriptor, :children, Map.get(descriptor, "children", []))

  @spec signal_bindings(map()) :: [map()]
  def signal_bindings(descriptor),
    do: Map.get(descriptor, :signal_bindings, Map.get(descriptor, "signal_bindings", []))

  @spec binding(map(), String.t() | [String.t()]) :: map() | nil
  def binding(descriptor, events) do
    events = List.wrap(events)

    Enum.find(signal_bindings(descriptor), fn binding ->
      Map.get(binding, :event, Map.get(binding, "event")) in events
    end)
  end

  @spec intent(map() | nil, String.t() | nil) :: String.t() | nil
  def intent(nil, default), do: default

  def intent(binding, default) do
    payload = Map.get(binding, :payload, Map.get(binding, "payload", %{}))

    payload
    |> Map.get("intent", Map.get(payload, :intent, default))
    |> normalize_string()
  end

  @spec binding_value(map() | nil, String.t()) :: term()
  def binding_value(nil, _key), do: nil

  def binding_value(binding, key) do
    payload = Map.get(binding, :payload, Map.get(binding, "payload", %{}))
    Map.get(payload, key, Map.get(payload, String.to_atom(key)))
  end

  @spec classes(map(), [String.t()]) :: [String.t()]
  def classes(descriptor, base_classes \\ []) do
    style = props(descriptor) |> Map.get("style", %{})
    base_classes ++ Compiler.compile(style)
  end

  @spec inline_style(map()) :: String.t() | nil
  def inline_style(descriptor) do
    style = props(descriptor) |> Map.get("style", %{})
    Compiler.inline(style)
  end

  @spec hook_name(map()) :: String.t() | nil
  def hook_name(descriptor), do: Assets.hook_name(kind(descriptor))

  @spec visible?(map()) :: boolean()
  def visible?(descriptor) do
    descriptor
    |> props()
    |> Map.get("visible", true)
    |> truthy?()
  end

  @spec truthy?(term()) :: boolean()
  def truthy?(value) when value in [false, nil, "false", "0", 0], do: false
  def truthy?(_value), do: true

  @spec scalar_string(term()) :: String.t() | nil
  def scalar_string(nil), do: nil
  def scalar_string(value) when is_binary(value), do: value
  def scalar_string(value) when is_atom(value), do: Atom.to_string(value)
  def scalar_string(value), do: to_string(value)

  defp normalize_string(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_string(value) when is_atom(value),
    do: value |> Atom.to_string() |> normalize_string()

  defp normalize_string(_value), do: nil
end
