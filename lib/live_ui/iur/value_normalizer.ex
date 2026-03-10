defmodule LiveUi.IUR.ValueNormalizer do
  @moduledoc """
  Small normalization helpers shared by the local IUR interpreter.
  """

  @spec kind(map()) :: String.t() | nil
  def kind(payload) when is_map(payload) do
    payload
    |> fetch("kind")
    |> normalize_string()
  end

  @spec id(map(), String.t()) :: String.t()
  def id(payload, fallback) when is_map(payload) and is_binary(fallback) do
    case payload |> fetch("id") |> normalize_string() do
      nil -> fallback
      id -> id
    end
  end

  @spec children(map()) :: [term()]
  def children(payload) when is_map(payload) do
    case fetch(payload, "children") do
      children when is_list(children) -> children
      _ -> []
    end
  end

  @spec props(map()) :: map()
  def props(payload) when is_map(payload) do
    explicit_props = fetch(payload, "props")

    props =
      if is_map(explicit_props) do
        explicit_props
      else
        payload
        |> Map.drop([
          :__struct__,
          "id",
          :id,
          "kind",
          :kind,
          "children",
          :children,
          "props",
          :props,
          "schema",
          :schema,
          "source",
          :source,
          "version",
          :version
        ])
      end

    normalize_map(props)
  end

  @spec normalize_map(map()) :: map()
  def normalize_map(map) when is_map(map) do
    Enum.into(map, %{}, fn {key, value} -> {normalize_key(key), normalize_value(value)} end)
  end

  defp normalize_value(value) when is_map(value), do: normalize_map(value)
  defp normalize_value(value) when is_list(value), do: Enum.map(value, &normalize_value/1)
  defp normalize_value(value), do: value

  defp normalize_key(key) when is_atom(key), do: Atom.to_string(key)
  defp normalize_key(key) when is_binary(key), do: key
  defp normalize_key(key), do: to_string(key)

  defp fetch(map, "kind"), do: Map.get(map, "kind", Map.get(map, :kind))
  defp fetch(map, "id"), do: Map.get(map, "id", Map.get(map, :id))
  defp fetch(map, "children"), do: Map.get(map, "children", Map.get(map, :children))
  defp fetch(map, "props"), do: Map.get(map, "props", Map.get(map, :props))

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
