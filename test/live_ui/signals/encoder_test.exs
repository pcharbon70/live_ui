defmodule LiveUi.Signals.EncoderTest do
  use ExUnit.Case, async: true

  alias Jido.Signal
  alias LiveUi.Signals.Encoder

  test "normalizes button clicks into concrete jido signals" do
    assert {:ok, %Signal{} = signal} =
             Encoder.encode(
               "click",
               %{"widget_id" => "save", "widget_kind" => "button", "intent" => "activate"},
               %{
                 signal_source: "/host/live_ui"
               }
             )

    assert signal.type == "live_ui.button.activate"
    assert signal.subject == "save"
    assert signal.source == "/host/live_ui"
  end

  test "includes value and form context for input events" do
    assert {:ok, signal} =
             Encoder.encode("change", %{
               "widget_id" => "name",
               "widget_kind" => "text_input",
               "value" => "Pascal",
               "form" => %{"name" => "Pascal"}
             })

    assert signal.data.payload == %{"form" => %{"name" => "Pascal"}, "value" => "Pascal"}
    assert signal.type == "live_ui.text_input.change"
  end

  test "decodes scoped attrs for multi-event elements without leaking other event scopes" do
    assert {:ok, signal} =
             Encoder.encode("submit", %{
               "widget_id" => "name",
               "widget_kind" => "text_input",
               "value" => "Pascal",
               "event_change_intent" => "update_name",
               "event_submit_intent" => "commit_name",
               "event_submit_source" => "blur",
               "event_submit_json_meta" => Jason.encode!(%{"reason" => "enter"})
             })

    assert signal.type == "live_ui.text_input.commit_name"

    assert signal.data.payload == %{
             "meta" => %{"reason" => "enter"},
             "source" => "blur",
             "value" => "Pascal"
           }
  end

  test "preserves stable payloads for hook-driven advanced widgets" do
    assert {:ok, signal} =
             Encoder.encode("resize", %{
               "widget_id" => "main-split",
               "widget_kind" => "split_pane",
               "intent" => "resize",
               "sizes" => [30, 70],
               "active_pane" => "left"
             })

    assert signal.type == "live_ui.split_pane.resize"
    assert signal.data.payload == %{"active_pane" => "left", "sizes" => [30, 70]}
  end
end
