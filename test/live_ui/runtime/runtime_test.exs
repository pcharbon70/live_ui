defmodule LiveUi.RuntimeTest do
  use ExUnit.Case, async: true

  alias Jido.Signal
  alias LiveUi.ConfigurationError
  alias LiveUi.Runtime
  alias LiveUi.Runtime.Model
  alias LiveUi.TestSupport.CounterScreen
  alias LiveUi.TestSupport.InvalidScreen
  alias LiveUi.TestSupport.InvalidIurScreen

  test "initializes the runtime model from a valid source module" do
    assert {:ok, %Model{} = model} =
             Runtime.init(
               source: CounterScreen,
               source_opts: [count: 2, mount_token: "boot-1"],
               runtime_context: %{request_id: "req-1"}
             )

    assert model.status == :ready
    assert model.source.module == CounterScreen
    assert model.screen_state == %{count: 2, initialized?: true, mount_token: "boot-1"}

    assert model.iur_tree == %{
             id: "counter-root",
             kind: "vbox",
             spacing: 2,
             meta: %{initialized?: true, mount_token: "boot-1"},
             children: [
               %{
                 id: "counter-label",
                 kind: "text",
                 content: "Count: 2",
                 style: %{class: "counter-value"}
               },
               %{
                 id: "increment-button",
                 kind: "button",
                 label: "Increment",
                 on_click: %{intent: "activate", payload: %{delta: 1}}
               }
             ]
           }

    assert model.descriptor_tree.kind == "vbox"
    assert Enum.map(model.descriptor_tree.children, & &1.kind) == ["text", "button"]

    assert model.signal_bindings == [
             %{
               event: "on_click",
               widget_id: "increment-button",
               widget_kind: "button",
               payload: %{"intent" => "activate", "payload" => %{"delta" => 1}}
             }
           ]

    assert model.render_metadata == %{node_count: 3, root_id: "counter-root", root_kind: "vbox"}
    assert model.widget_state == %{}
    assert model.runtime_context == %{request_id: "req-1"}
  end

  test "encodes liveview event payloads as concrete jido signals" do
    {:ok, model} =
      Runtime.init(
        source: CounterScreen,
        source_opts: [count: 1],
        runtime_context: %{signal_source: "/host/live_ui", request_id: "req-2"}
      )

    assert {:ok, %Model{} = updated_model} =
             Runtime.handle_event(model, "click", %{
               "delta" => "3",
               "intent" => "activate",
               "widget_id" => "increment-button",
               "widget_kind" => "button"
             })

    assert updated_model.event_count == 1
    assert updated_model.screen_state.count == 4
    assert %Signal{} = updated_model.last_signal
    assert updated_model.last_signal.type == "live_ui.button.activate"
    assert updated_model.last_signal.source == "/host/live_ui"
    assert updated_model.last_signal.subject == "increment-button"

    assert updated_model.last_signal.data == %{
             intent: "activate",
             payload: %{"delta" => "3"},
             runtime_context: %{signal_source: "/host/live_ui", request_id: "req-2"},
             widget_id: "increment-button",
             widget_kind: "button"
           }

    assert hd(updated_model.descriptor_tree.children).props["content"] == "Count: 4"
  end

  test "accepts passthrough jido signals without rebuilding metadata from the payload" do
    {:ok, model} =
      Runtime.init(source: CounterScreen, source_opts: [count: 5], runtime_context: %{})

    signal =
      Signal.new!(
        "live_ui.button.increment",
        %{payload: %{"delta" => 2}, widget_id: "increment-button", widget_kind: "button"},
        source: "/host/live_ui",
        subject: "increment-button"
      )

    assert {:ok, %Model{} = updated_model} =
             Runtime.handle_event(model, "ignored", %{"signal" => signal})

    assert updated_model.screen_state.count == 7
    assert updated_model.last_signal == signal
    assert updated_model.screen_state.last_signal_type == "live_ui.button.increment"
    assert hd(updated_model.descriptor_tree.children).props["content"] == "Count: 7"
  end

  test "rejects event payloads missing required widget metadata" do
    {:ok, model} = Runtime.init(source: CounterScreen, source_opts: [], runtime_context: %{})

    assert {:error, %ConfigurationError{} = error} =
             Runtime.handle_event(model, "click", %{"delta" => 1, "widget_kind" => "button"})

    assert error.message =~ "missing required metadata"
    assert error.details.field == "widget_id"
  end

  test "returns configuration errors for invalid source modules" do
    assert {:error, %ConfigurationError{} = error} =
             Runtime.init(source: InvalidScreen, source_opts: [], runtime_context: %{})

    assert error.message =~ "missing required callbacks"
  end

  test "returns interpreter failures when the source emits an unsupported node kind" do
    assert {:error, %ConfigurationError{} = error} =
             Runtime.init(source: InvalidIurScreen, source_opts: [], runtime_context: %{})

    assert error.message =~ "unsupported"
  end
end
