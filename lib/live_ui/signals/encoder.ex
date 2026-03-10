defmodule LiveUi.Signals.Encoder do
  @moduledoc """
  Normalizes LiveView payloads into concrete `%Jido.Signal{}` structs.
  """

  alias Jido.Signal
  alias LiveUi.ConfigurationError

  @spec encode(String.t() | atom(), map(), map()) ::
          {:ok, Signal.t()} | {:error, ConfigurationError.t()}
  def encode(event_name, payload, runtime_context \\ %{})

  def encode(event_name, payload, runtime_context)
      when is_map(payload) and is_map(runtime_context) do
    {:ok, normalize_signal(event_name, payload, runtime_context)}
  rescue
    error in ConfigurationError -> {:error, error}
  end

  def encode(_event_name, _payload, _runtime_context) do
    {:error, ConfigurationError.new("live_ui event payload must be a map")}
  end

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
        case String.trim(value) do
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

  defp signal_source(runtime_context) do
    runtime_context
    |> optional_payload_value(:signal_source, "/live_ui")
    |> normalize_signal_source()
  end

  defp normalize_signal_source(source) when is_binary(source) do
    case String.trim(source) do
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

  defp normalize_signal_type_part(value) when is_atom(value),
    do: value |> Atom.to_string() |> normalize_signal_type_part()
end
