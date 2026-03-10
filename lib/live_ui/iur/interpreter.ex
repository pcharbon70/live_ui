defmodule LiveUi.IUR.Interpreter do
  @moduledoc """
  Minimal IUR-to-descriptor normalization used by the local compliance suite.
  """

  alias LiveUi.ConfigurationError
  alias LiveUi.IUR.Dependency
  alias LiveUi.IUR.ValueNormalizer

  @signal_fields ["on_change", "on_click", "on_submit", "signal"]

  @spec interpret(map() | struct()) :: {:ok, map()} | {:error, ConfigurationError.t()}
  def interpret(payload) when is_map(payload) do
    payload = if Map.has_key?(payload, :__struct__), do: Map.from_struct(payload), else: payload

    with :ok <- Dependency.validate_markers(payload),
         kind when is_binary(kind) <- ValueNormalizer.kind(payload),
         true <- LiveUi.WidgetRegistry.supported_kind?(kind),
         {:ok, children} <- interpret_children(ValueNormalizer.children(payload)),
         id <- ValueNormalizer.id(payload, fallback_id(kind)),
         props <- ValueNormalizer.props(payload) do
      {:ok,
       %{
         id: id,
         kind: kind,
         props: props,
         children: children,
         signal_bindings: extract_signal_bindings(payload, id, kind)
       }}
    else
      nil ->
        {:error, ConfigurationError.new("unified_iur payload is missing a supported kind")}

      false ->
        {:error,
         ConfigurationError.new("unified_iur node kind is unsupported", %{
           kind: ValueNormalizer.kind(payload)
         })}

      {:error, %ConfigurationError{} = error} ->
        {:error, error}
    end
  end

  def interpret(_payload) do
    {:error, ConfigurationError.new("unified_iur payload must be a map or struct")}
  end

  defp interpret_children(children) do
    children
    |> Enum.map(&interpret/1)
    |> Enum.reduce_while({:ok, []}, fn
      {:ok, descriptor}, {:ok, acc} -> {:cont, {:ok, acc ++ [descriptor]}}
      {:error, error}, _acc -> {:halt, {:error, error}}
    end)
  end

  defp extract_signal_bindings(payload, widget_id, widget_kind) do
    Enum.flat_map(@signal_fields, fn field ->
      case fetch(payload, field) do
        binding when is_map(binding) ->
          [
            %{
              event: field,
              widget_id: widget_id,
              widget_kind: widget_kind,
              payload: ValueNormalizer.normalize_map(binding)
            }
          ]

        _ ->
          []
      end
    end)
  end

  defp fetch(map, "on_change"), do: Map.get(map, "on_change", Map.get(map, :on_change))
  defp fetch(map, "on_click"), do: Map.get(map, "on_click", Map.get(map, :on_click))
  defp fetch(map, "on_submit"), do: Map.get(map, "on_submit", Map.get(map, :on_submit))
  defp fetch(map, "signal"), do: Map.get(map, "signal", Map.get(map, :signal))
  defp fallback_id(kind), do: "#{kind}-#{System.unique_integer([:positive])}"
end
