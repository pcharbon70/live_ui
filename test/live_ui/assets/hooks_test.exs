defmodule LiveUi.Assets.HooksTest do
  use ExUnit.Case, async: true

  alias LiveUi.Assets

  test "exposes a host-consumable hook manifest for advanced widgets" do
    hooks = Assets.hooks()
    js_entrypoint = Assets.javascript_entrypoint_path()
    stylesheet = Assets.stylesheet_entrypoint_path()

    assert hooks["viewport"] == "LiveUi.Viewport"
    assert hooks["split_pane"] == "LiveUi.SplitPane"
    assert hooks["command_palette"] == "LiveUi.CommandPalette"
    assert hooks["canvas"] == "LiveUi.Canvas"
    assert Assets.hook_name(:split_pane) == "LiveUi.SplitPane"
    assert Assets.javascript_entrypoint() == "live_ui"
    assert Assets.javascript_import_path() == "../../deps/live_ui/assets/js/live_ui"
    assert Assets.stylesheet_entrypoint() == "live_ui.css"
    assert Assets.stylesheet_import_path() == "../../deps/live_ui/assets/css/live_ui.css"
    assert File.exists?(js_entrypoint)
    assert File.exists?(stylesheet)

    source = File.read!(js_entrypoint)
    stylesheet_source = File.read!(stylesheet)

    assert source =~ "const LiveUiHooks ="
    assert source =~ "\"LiveUi.Viewport\": Viewport"
    assert source =~ "\"LiveUi.SplitPane\": SplitPane"
    assert source =~ "\"LiveUi.CommandPalette\": CommandPalette"
    assert source =~ "\"LiveUi.Canvas\": Canvas"
    assert source =~ "export default LiveUiHooks"

    assert stylesheet_source =~ "--live-ui-color-accent"
    assert stylesheet_source =~ "--live-ui-typography-family"
    assert stylesheet_source =~ "--live-ui-elevation-modal"
    assert stylesheet_source =~ ".live-ui-theme"
  end
end
