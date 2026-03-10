defmodule LiveUi.Source do
  @moduledoc """
  Source module validation and metadata for DSL-backed screens.
  """

  alias LiveUi.ConfigurationError

  @required_callbacks [init: 1, update: 2, view: 1]

  @enforce_keys [:module]
  defstruct [:module, opts: []]

  @type t :: %__MODULE__{
          module: module(),
          opts: keyword()
        }

  @spec new(module(), keyword()) :: t()
  def new(source_module, opts \\ []) when is_list(opts) do
    validate_module!(source_module)
    %__MODULE__{module: source_module, opts: Keyword.new(opts)}
  end

  @spec validate_module!(module()) :: :ok
  def validate_module!(source_module) do
    cond do
      not is_atom(source_module) ->
        raise ConfigurationError.new("live_ui source must be a module", %{source: source_module})

      not module_reference?(source_module) ->
        raise ConfigurationError.new(
                "live_ui source must be a module reference",
                %{source: inspect(source_module)}
              )

      not Code.ensure_loaded?(source_module) ->
        raise ConfigurationError.new(
                "live_ui source module is not available",
                %{source: inspect(source_module)}
              )

      missing_callbacks(source_module) != [] ->
        raise ConfigurationError.new("live_ui source module is missing required callbacks", %{
                source: inspect(source_module),
                missing: missing_callbacks(source_module)
              })

      true ->
        :ok
    end
  end

  @spec module_reference?(module()) :: boolean()
  def module_reference?(source_module) when is_atom(source_module) do
    source_module
    |> Atom.to_string()
    |> String.starts_with?("Elixir.")
  end

  def module_reference?(_source_module), do: false

  defp missing_callbacks(source_module) do
    Enum.reject(@required_callbacks, fn {name, arity} ->
      function_exported?(source_module, name, arity)
    end)
  end
end
