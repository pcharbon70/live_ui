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
    intent = event_scoped_value(payload, event_name, :intent, normalize_event_name(event_name))

    signal_attrs = %{
      data: %{
        intent: intent,
        payload: signal_payload(payload, event_name, widget_kind),
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

  defp event_scoped_value(payload, event_name, key, default) do
    event_name = normalize_event_name(event_name)
    scoped_key = "event_#{event_name}_#{Atom.to_string(key)}"

    Map.get(
      payload,
      scoped_key,
      Map.get(payload, String.to_atom(scoped_key), optional_payload_value(payload, key, default))
    )
  end

  defp signal_payload(payload, event_name, widget_kind) do
    event_name = normalize_event_name(event_name)

    normalized =
      payload
      |> Enum.reduce(%{}, fn {key, value}, acc ->
        put_signal_payload(acc, normalize_payload_key(key), value, event_name)
      end)

    normalize_widget_payload(widget_kind, event_name, normalized, payload)
  end

  defp put_signal_payload(acc, key, value, event_name) do
    if key in [
         "_target",
         "intent",
         "signal",
         "widget_id",
         "widget_kind",
         "event_#{event_name}_intent"
       ] do
      acc
    else
      do_put_signal_payload(acc, key, value, event_name)
    end
  end

  defp do_put_signal_payload(acc, <<"event_", rest::binary>>, value, event_name) do
    event_prefix = "#{event_name}_"
    json_event_prefix = "#{event_prefix}json_"

    cond do
      String.starts_with?(rest, json_event_prefix) ->
        stripped_key = String.replace_prefix(rest, json_event_prefix, "")
        Map.put(acc, stripped_key, decode_json(value))

      String.starts_with?(rest, event_prefix) ->
        stripped_key = String.replace_prefix(rest, event_prefix, "")
        Map.put(acc, stripped_key, value)

      true ->
        acc
    end
  end

  defp do_put_signal_payload(acc, <<"json_", key::binary>>, value, _event_name),
    do: Map.put(acc, key, decode_json(value))

  defp do_put_signal_payload(acc, key, value, _event_name), do: Map.put(acc, key, value)

  defp normalize_payload_key(key) when is_binary(key), do: key
  defp normalize_payload_key(key) when is_atom(key), do: Atom.to_string(key)
  defp normalize_payload_key(key), do: to_string(key)

  defp decode_json(value) when is_binary(value) do
    case Jason.decode(value) do
      {:ok, decoded} -> decoded
      {:error, _reason} -> value
    end
  end

  defp decode_json(value), do: value

  defp normalize_widget_payload(widget_kind, _event_name, payload, raw_payload)
       when widget_kind in ["form_builder", "pick_list", "text_input"] do
    field_path = target_path(raw_payload)
    fallback_widget_id = Map.get(raw_payload, "widget_id", Map.get(raw_payload, :widget_id))
    field_name = Map.get(payload, "field_name") || List.last(field_path) || fallback_widget_id
    values = normalize_values(Map.get(payload, "form"))

    payload
    |> Map.drop(["form"])
    |> put_if_present(
      "field_id",
      Map.get(payload, "field_id") || fallback_widget_id || field_name
    )
    |> put_if_present("field_name", field_name)
    |> put_if_present("field_path", field_path)
    |> put_if_present("form_id", Map.get(payload, "form_id"))
    |> put_if_present("values", values)
    |> put_if_present("value", Map.get(payload, "value") || value_from_values(values, field_path))
    |> maybe_put_normalized("field_count", &normalize_integer/1)
  end

  defp normalize_widget_payload("table", _event_name, payload, _raw_payload) do
    payload
    |> maybe_put_normalized("row_index", &normalize_integer/1)
    |> maybe_put_normalized("column_index", &normalize_integer/1)
    |> maybe_put_normalized("selection_mode", &normalize_string/1)
  end

  defp normalize_widget_payload("tree_node", _event_name, payload, _raw_payload) do
    payload
    |> maybe_put_normalized("child_count", &normalize_integer/1)
    |> maybe_put_normalized("expanded", &normalize_boolean/1)
    |> maybe_put_normalized("next_expanded", &normalize_boolean/1)
    |> maybe_put_normalized("selected", &normalize_boolean/1)
  end

  defp normalize_widget_payload(_widget_kind, _event_name, payload, _raw_payload), do: payload

  defp target_path(raw_payload) do
    case Map.get(raw_payload, "_target", Map.get(raw_payload, :_target)) do
      nil -> []
      path when is_list(path) -> Enum.map(path, &normalize_string/1) |> Enum.reject(&is_nil/1)
      value when is_binary(value) -> [value]
      value when is_atom(value) -> [Atom.to_string(value)]
      _other -> []
    end
  end

  defp normalize_values(%{} = values), do: values
  defp normalize_values(_values), do: nil

  defp value_from_values(nil, _field_path), do: nil

  defp value_from_values(_values, []), do: nil

  defp value_from_values(values, [segment]),
    do: Map.get(values, segment, Map.get(values, safe_existing_atom(segment)))

  defp value_from_values(values, [segment | rest]) do
    next =
      Map.get(values, segment, Map.get(values, safe_existing_atom(segment)))

    if is_map(next), do: value_from_values(next, rest), else: nil
  end

  defp maybe_put_normalized(payload, key, fun) do
    case Map.fetch(payload, key) do
      {:ok, value} -> Map.put(payload, key, fun.(value))
      :error -> payload
    end
  end

  defp normalize_integer(value) when is_integer(value), do: value

  defp normalize_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} -> integer
      _other -> value
    end
  end

  defp normalize_integer(value), do: value

  defp normalize_boolean(value) when value in [true, false], do: value
  defp normalize_boolean("true"), do: true
  defp normalize_boolean("false"), do: false
  defp normalize_boolean(value), do: value

  defp normalize_string(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_string(nil), do: nil

  defp normalize_string(value) when is_atom(value),
    do: value |> Atom.to_string() |> normalize_string()

  defp normalize_string(value), do: to_string(value)

  defp put_if_present(payload, _key, nil), do: payload
  defp put_if_present(payload, _key, []), do: payload
  defp put_if_present(payload, key, value), do: Map.put(payload, key, value)

  defp safe_existing_atom(nil), do: nil

  defp safe_existing_atom(key) when is_binary(key) do
    String.to_existing_atom(key)
  rescue
    ArgumentError -> nil
  end

  defp safe_existing_atom(_key), do: nil

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
