defmodule LiveUi.Runtime do
  @moduledoc """
  Deterministic runtime shell shared by wrapper-based and dynamic entrypoints.
  """

  alias Jido.Signal
  alias LiveUi.ConfigurationError
  alias LiveUi.Runtime.Model
  alias LiveUi.Source

  @type init_opt ::
          {:runtime_context, map()}
          | {:source, module()}
          | {:source_opts, keyword()}

  @spec init([init_opt()]) :: {:ok, Model.t()} | {:error, Exception.t()}
  def init(opts) when is_list(opts) do
    source = Source.new(Keyword.fetch!(opts, :source), Keyword.get(opts, :source_opts, []))
    runtime_context = Keyword.get(opts, :runtime_context, %{})
    screen_state = init_screen_state(source)
    iur_tree = render_iur_tree(source, screen_state)

    {:ok,
     Model.new(
       runtime_context: runtime_context,
       source: source,
       screen_state: screen_state,
       iur_tree: iur_tree,
       status: :ready
     )}
  rescue
    error in [ConfigurationError, KeyError] -> {:error, error}
  end

  @spec handle_event(Model.t(), String.t() | atom(), map()) ::
          {:ok, Model.t()} | {:error, Exception.t()}
  def handle_event(%Model{} = model, event_name, payload) when is_map(payload) do
    signal = normalize_signal(event_name, payload, model.runtime_context)
    screen_state = update_screen_state(model.source, model.screen_state || %{}, signal)
    iur_tree = render_iur_tree(model.source, screen_state)

    {:ok,
     %Model{
       model
       | event_count: model.event_count + 1,
         error: nil,
         iur_tree: iur_tree,
         last_event: %{name: event_name, payload: payload},
         last_signal: signal,
         screen_state: screen_state,
         status: :ready
     }}
  rescue
    error in ConfigurationError -> {:error, error}
  end

  def handle_event(%Model{}, _event_name, _payload) do
    {:error, ConfigurationError.new("live_ui runtime events must provide a map payload")}
  end

  defp init_screen_state(%Source{module: source_module, opts: source_opts}) do
    source_module
    |> apply(:init, [source_opts])
    |> normalize_state_result(:init)
  end

  defp update_screen_state(%Source{module: source_module}, screen_state, signal) do
    source_module
    |> apply(:update, [screen_state, signal])
    |> normalize_state_result(:update)
  end

  defp render_iur_tree(%Source{module: source_module}, screen_state) do
    apply(source_module, :view, [screen_state])
  end

  defp normalize_state_result(result, _callback_name) when is_map(result), do: result

  defp normalize_state_result({:ok, result}, callback_name),
    do: normalize_state_result(result, callback_name)

  defp normalize_state_result(other, callback_name) do
    raise ConfigurationError.new(
            "live_ui source #{callback_name}/#{callback_arity(callback_name)} must return a map or {:ok, map}",
            %{
              callback: callback_name,
              return: inspect(other)
            }
          )
  end

  defp callback_arity(:init), do: 1
  defp callback_arity(:update), do: 2

  defp normalize_signal(_event_name, %{"signal" => %Signal{} = signal}, _runtime_context),
    do: signal

  defp normalize_signal(_event_name, %{signal: %Signal{} = signal}, _runtime_context), do: signal

  defp normalize_signal(_event_name, %{"signal" => signal}, _runtime_context) do
    raise ConfigurationError.new("live_ui event payload signal must be a Jido.Signal struct", %{
            signal: inspect(signal)
          })
  end

  defp normalize_signal(_event_name, %{signal: signal}, _runtime_context) do
    raise ConfigurationError.new("live_ui event payload signal must be a Jido.Signal struct", %{
            signal: inspect(signal)
          })
  end

  defp normalize_signal(event_name, payload, runtime_context) do
    widget_id = required_payload_value(payload, :widget_id)
    widget_kind = required_payload_value(payload, :widget_kind)
    intent = optional_payload_value(payload, :intent, normalize_event_name(event_name))

    signal_attrs = %{
      data: %{
        intent: intent,
        payload: signal_payload(payload),
        runtime_context: runtime_context,
        widget_id: widget_id,
        widget_kind: widget_kind
      },
      source: signal_source(runtime_context),
      subject: widget_id,
      type: signal_type(widget_kind, intent)
    }

    case Signal.new(signal_attrs) do
      {:ok, signal} ->
        signal

      {:error, reason} ->
        raise ConfigurationError.new("live_ui could not encode event as Jido.Signal", %{
                event_name: normalize_event_name(event_name),
                reason: inspect(reason),
                signal_attrs: inspect(signal_attrs)
              })
    end
  end

  defp normalize_event_name(event_name) when is_binary(event_name), do: event_name
  defp normalize_event_name(event_name) when is_atom(event_name), do: Atom.to_string(event_name)

  defp required_payload_value(payload, key) do
    case optional_payload_value(payload, key) do
      value when is_binary(value) ->
        String.trim(value)
        |> case do
          "" ->
            raise ConfigurationError.new("live_ui event payload is missing required metadata", %{
                    field: Atom.to_string(key),
                    payload: inspect(payload)
                  })

          normalized ->
            normalized
        end

      value when is_atom(value) and not is_nil(value) ->
        Atom.to_string(value)

      nil ->
        raise ConfigurationError.new("live_ui event payload is missing required metadata", %{
                field: Atom.to_string(key),
                payload: inspect(payload)
              })

      other ->
        raise ConfigurationError.new("live_ui event payload metadata must be a string or atom", %{
                field: Atom.to_string(key),
                value: inspect(other)
              })
    end
  end

  defp optional_payload_value(payload, key, default \\ nil) do
    Map.get(payload, Atom.to_string(key), Map.get(payload, key, default))
  end

  defp signal_payload(payload) do
    payload
    |> Map.drop(["intent", "signal", "widget_id", "widget_kind"])
    |> Map.drop([:intent, :signal, :widget_id, :widget_kind])
  end

  defp signal_source(runtime_context) when is_map(runtime_context) do
    runtime_context
    |> optional_payload_value(:signal_source, "/live_ui")
    |> normalize_signal_source()
  end

  defp normalize_signal_source(source) when is_binary(source) do
    source
    |> String.trim()
    |> case do
      "" -> "/live_ui"
      normalized -> normalized
    end
  end

  defp normalize_signal_source(source) when is_atom(source),
    do: source |> Atom.to_string() |> normalize_signal_source()

  defp normalize_signal_source(_source), do: "/live_ui"

  defp signal_type(widget_kind, intent) do
    ["live_ui", widget_kind, intent]
    |> Enum.map(&normalize_signal_type_part/1)
    |> Enum.join(".")
  end

  defp normalize_signal_type_part(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9_]+/u, "_")
    |> String.trim("_")
    |> case do
      "" -> raise ConfigurationError.new("live_ui signal type part cannot be empty")
      <<first::utf8, _rest::binary>> = normalized when first in ?a..?z -> normalized
      normalized -> "x_#{normalized}"
    end
  end

  defp normalize_signal_type_part(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> normalize_signal_type_part()
  end
end
