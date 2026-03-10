defmodule LiveUi.Components.WidgetRenderingTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, only: [render_component: 2, rendered_to_string: 1]

  alias LiveUi.WidgetRegistry

  test "renders stateless widgets with stable css tokens" do
    rendered =
      render_component(&WidgetRegistry.render/1,
        descriptor: %{
          id: "headline",
          kind: "text",
          props: %{"text" => "Hello", "style" => %{"class" => "hero", "tone" => "accent"}}
        }
      )
      |> rendered_to_string()

    assert rendered =~ "Hello"
    assert rendered =~ "live-ui-text"
    assert rendered =~ "hero"
    assert rendered =~ "tone-accent"
  end

  test "renders stateful composites with hook metadata" do
    rendered =
      render_component(&WidgetRegistry.render/1,
        descriptor: %{
          id: "main-split",
          kind: "split_pane",
          props: %{"sizes" => [30, 70], "style" => %{"gap" => 2}}
        }
      )
      |> rendered_to_string()

    assert rendered =~ "live-ui-layout--split_pane"
    assert rendered =~ "LiveUi.SplitPane"
    assert rendered =~ "gap-2"
    refute rendered =~ "align-items: nil"
  end

  test "renders layouts by recursively dispatching child descriptors" do
    rendered =
      render_component(&WidgetRegistry.render/1,
        descriptor: %{
          id: "stack",
          kind: "vbox",
          props: %{},
          children: [
            %{id: "label-1", kind: "label", props: %{"text" => "Name"}},
            %{id: "input-1", kind: "text_input", props: %{"value" => "Pascal"}}
          ]
        }
      )
      |> rendered_to_string()

    assert rendered =~ "live-ui-layout--vbox"
    assert rendered =~ "Name"
    assert rendered =~ "value=&quot;Pascal&quot;"
  end
end
