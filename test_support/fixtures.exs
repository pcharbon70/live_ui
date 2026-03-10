defmodule LiveUi.TestSupport.CounterScreen do
  @moduledoc false

  alias Jido.Signal

  def init(opts) do
    %{
      count: Keyword.get(opts, :count, 0),
      initialized?: true,
      mount_token: Keyword.get(opts, :mount_token)
    }
  end

  def update(state, %Signal{} = signal) do
    increment =
      signal
      |> payload_value("delta", 1)
      |> normalize_integer()

    state
    |> Map.update!(:count, &(&1 + increment))
    |> Map.put(:last_signal_id, signal.id)
    |> Map.put(:last_signal_type, signal.type)
    |> Map.put(:last_signal_subject, signal.subject)
  end

  def view(state) do
    %{
      id: "counter-root",
      kind: "vbox",
      spacing: 2,
      children: [
        %{
          id: "counter-label",
          kind: "text",
          content: "Count: #{state.count}",
          style: %{class: "counter-value"}
        },
        %{
          id: "increment-button",
          kind: "button",
          label: "Increment",
          on_click: %{intent: "activate", payload: %{delta: 1}}
        }
      ],
      meta: %{
        initialized?: state.initialized?,
        mount_token: state.mount_token
      }
    }
  end

  defp payload_value(%Signal{data: %{payload: payload}}, key, default) when is_map(payload) do
    Map.get(payload, key, Map.get(payload, String.to_atom(key), default))
  end

  defp payload_value(_signal, _key, default), do: default

  defp normalize_integer(value) when is_integer(value), do: value

  defp normalize_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} -> integer
      _other -> 1
    end
  end

  defp normalize_integer(_value), do: 1
end

defmodule LiveUi.TestSupport.RawIur do
  @moduledoc false

  def counter_tree(count \\ 1, opts \\ []) do
    %{
      "schema" => "unified_iur",
      "source" => "live_ui_test",
      "version" => "1.0.0",
      "id" => "counter-root",
      "kind" => "vbox",
      "spacing" => 2,
      "meta" => %{
        "initialized?" => true,
        "mount_token" => Keyword.get(opts, :mount_token)
      },
      "children" => [
        %{
          "id" => "counter-label",
          "kind" => "text",
          "content" => "Count: #{count}",
          "style" => %{"class" => "counter-value"}
        },
        %{
          "id" => "increment-button",
          "kind" => "button",
          "label" => "Increment",
          "on_click" => %{"intent" => "activate", "payload" => %{"delta" => 1}}
        }
      ]
    }
  end
end

defmodule LiveUi.TestSupport.InvalidScreen do
  @moduledoc false

  def init(_opts), do: %{}
  def update(state, _signal), do: state
end

defmodule LiveUi.TestSupport.InvalidIurScreen do
  @moduledoc false

  def init(_opts), do: %{}
  def update(state, _signal), do: state
  def view(_state), do: %{kind: "totally_unknown", id: "bad-root"}
end

defmodule LiveUi.TestSupport.WrapperLive do
  @moduledoc false

  use LiveUi.Screen, source: LiveUi.TestSupport.CounterScreen

  def liveui_context(params, _session, _socket) do
    %{request_id: Map.get(params, "request_id"), signal_source: "/host/live_ui"}
  end

  def liveui_source_opts(_params, session, _socket) do
    [count: Map.get(session, "count", 0), mount_token: Map.get(session, "mount_token")]
  end
end
