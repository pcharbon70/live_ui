defmodule LiveUi.Host.EntrypointParityTest do
  use ExUnit.Case, async: true

  alias LiveUi
  alias LiveUi.Live.DynamicLive
  alias LiveUi.TestSupport.CounterScreen
  alias LiveUi.TestSupport.WrapperLive
  alias Phoenix.LiveView.Socket

  test "wrapper and dynamic entrypoints delegate to the same runtime model shape" do
    wrapper_socket = socket_for(WrapperLive, "wrapper-parity", :show)
    dynamic_socket = socket_for(DynamicLive, "dynamic-parity", nil)

    {:ok, wrapper_mounted} =
      WrapperLive.mount(
        %{"request_id" => "parity-1"},
        %{"count" => 4, "mount_token" => "same"},
        wrapper_socket
      )

    {:ok, dynamic_mounted} =
      DynamicLive.mount(
        %{"request_id" => "parity-2"},
        LiveUi.dynamic_session(CounterScreen, source_opts: [count: 4, mount_token: "same"]),
        dynamic_socket
      )

    wrapper_model = wrapper_mounted.assigns.live_ui_model
    dynamic_model = dynamic_mounted.assigns.live_ui_model

    assert wrapper_model.source.module == dynamic_model.source.module
    assert wrapper_model.screen_state == dynamic_model.screen_state
    assert wrapper_model.iur_tree == dynamic_model.iur_tree
    assert wrapper_model.status == :ready
    assert dynamic_model.status == :ready
    assert Map.keys(Map.from_struct(wrapper_model)) == Map.keys(Map.from_struct(dynamic_model))
  end

  defp socket_for(view, id, live_action) do
    %Socket{id: id, view: view, assigns: %{__changed__: %{}, live_action: live_action}}
  end
end
