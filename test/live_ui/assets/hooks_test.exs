defmodule LiveUi.Assets.HooksTest do
  use ExUnit.Case, async: true

  alias LiveUi.Assets

  test "exposes a host-consumable hook manifest for advanced widgets" do
    hooks = Assets.hooks()

    assert hooks["viewport"] == "LiveUi.Viewport"
    assert hooks["split_pane"] == "LiveUi.SplitPane"
    assert hooks["command_palette"] == "LiveUi.CommandPalette"
    assert hooks["canvas"] == "LiveUi.Canvas"
    assert Assets.hook_name(:split_pane) == "LiveUi.SplitPane"
    assert Assets.javascript_entrypoint() == "live_ui"
  end
end
