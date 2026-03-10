defmodule LiveUi.IUR.Dependency do
  @moduledoc """
  Validates optional canonical schema markers on incoming IUR payloads.
  """

  alias LiveUi.ConfigurationError

  @schema "unified_iur"
  @marker_keys ["schema", "source", "version"]

  @spec validate_markers(map()) :: :ok | {:error, ConfigurationError.t()}
  def validate_markers(payload) when is_map(payload) do
    markers =
      Enum.reduce(@marker_keys, %{}, fn key, acc -> Map.put(acc, key, fetch(payload, key)) end)

    cond do
      Enum.all?(@marker_keys, &blank?(markers[&1])) ->
        :ok

      Enum.any?(@marker_keys, &blank?(markers[&1])) ->
        {:error,
         ConfigurationError.new("incomplete unified_iur schema markers", %{markers: markers})}

      markers["schema"] != @schema ->
        {:error,
         ConfigurationError.new("unsupported unified_iur schema marker", %{
           schema: markers["schema"]
         })}

      true ->
        :ok
    end
  end

  def validate_markers(_payload) do
    {:error, ConfigurationError.new("unified_iur payload must be a map")}
  end

  @spec markers_present?(map()) :: boolean()
  def markers_present?(payload) when is_map(payload) do
    Enum.any?(@marker_keys, fn key -> not blank?(fetch(payload, key)) end)
  end

  def markers_present?(_payload), do: false

  defp fetch(map, "schema"), do: Map.get(map, "schema", Map.get(map, :schema))
  defp fetch(map, "source"), do: Map.get(map, "source", Map.get(map, :source))
  defp fetch(map, "version"), do: Map.get(map, "version", Map.get(map, :version))
  defp blank?(value), do: not (is_binary(value) and String.trim(value) != "")
end
