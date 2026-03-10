defmodule LiveUi.Style.Compiler do
  @moduledoc """
  Maps normalized style metadata into stable CSS tokens.
  """

  @spec compile(map()) :: [String.t()]
  def compile(styles) when is_map(styles) do
    styles
    |> Enum.flat_map(fn
      {key, value} when key in [:class, "class"] and is_binary(value) ->
        value |> String.split(~r/\s+/, trim: true)

      {key, value} when key in [:variant, "variant"] and is_binary(value) ->
        ["variant-#{value}"]

      {key, value} when key in [:tone, "tone"] and is_binary(value) ->
        ["tone-#{value}"]

      {key, value} when key in [:gap, "gap"] ->
        ["gap-#{value}"]

      _other ->
        []
    end)
    |> Enum.uniq()
  end

  def compile(_styles), do: []
end
