defmodule LiveUi.RuntimeTest do
  use ExUnit.Case, async: true

  alias Jido.Signal
  alias LiveUi.ConfigurationError
  alias LiveUi.Runtime
  alias LiveUi.Runtime.Model
  alias LiveUi.TestSupport.CounterScreen
  alias LiveUi.TestSupport.InvalidScreen

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
             kind: :counter,
             count: 2,
             initialized?: true,
             mount_token: "boot-1"
           }

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
end
