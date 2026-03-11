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

  test "renders descriptor-defined click payload attrs for buttons" do
    rendered =
      render_component(&WidgetRegistry.render/1,
        descriptor: %{
          id: "increment-button",
          kind: "button",
          props: %{"label" => "Increment"},
          signal_bindings: [
            %{
              event: "on_click",
              widget_id: "increment-button",
              widget_kind: "button",
              payload: %{
                "intent" => "activate",
                "payload" => %{"delta" => 2, "source" => "counter"}
              }
            }
          ]
        }
      )
      |> rendered_to_string()

    assert rendered =~ "phx-click=&quot;click&quot;"
    assert rendered =~ "phx-value-event_click_intent=&quot;activate&quot;"
    assert rendered =~ "phx-value-event_click_delta=&quot;2&quot;"
    assert rendered =~ "phx-value-event_click_source=&quot;counter&quot;"
  end

  test "renders scoped attrs for multi-event text inputs" do
    rendered =
      render_component(&WidgetRegistry.render/1,
        descriptor: %{
          id: "name-input",
          kind: "text_input",
          props: %{"form_id" => "profile-form", "name" => "name", "value" => "Pascal"},
          signal_bindings: [
            %{
              event: "on_change",
              widget_id: "name-input",
              widget_kind: "text_input",
              payload: %{"intent" => "update_name"}
            },
            %{
              event: "on_submit",
              widget_id: "name-input",
              widget_kind: "text_input",
              payload: %{"intent" => "commit_name", "payload" => %{"source" => "blur"}}
            }
          ]
        }
      )
      |> rendered_to_string()

    assert rendered =~ "phx-change=&quot;change&quot;"
    assert rendered =~ "phx-blur=&quot;submit&quot;"
    assert rendered =~ "phx-value-event_change_intent=&quot;update_name&quot;"
    assert rendered =~ "phx-value-event_submit_intent=&quot;commit_name&quot;"
    assert rendered =~ "phx-value-event_change_field_id=&quot;name-input&quot;"
    assert rendered =~ "phx-value-event_change_field_name=&quot;name&quot;"
    assert rendered =~ "phx-value-event_change_form_id=&quot;profile-form&quot;"
    assert rendered =~ "phx-value-event_submit_source=&quot;blur&quot;"
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

  test "renders table interactions with distinct row and sort payload attrs" do
    rendered =
      render_component(&WidgetRegistry.render/1,
        descriptor: %{
          id: "users-table",
          kind: "table",
          props: %{
            "columns" => [%{"key" => "name", "header" => "Name"}],
            "data" => [%{"name" => "Pascal"}],
            "sort_column" => "name",
            "sort_direction" => "desc"
          },
          signal_bindings: [
            %{
              event: "on_row_select",
              widget_id: "users-table",
              widget_kind: "table",
              payload: %{"intent" => "select_row"}
            },
            %{
              event: "on_sort",
              widget_id: "users-table",
              widget_kind: "table",
              payload: %{"intent" => "sort_rows", "payload" => %{"direction" => "asc"}}
            }
          ]
        }
      )
      |> rendered_to_string()

    assert rendered =~ "phx-value-event_click_sort_column=&quot;name&quot;"
    assert rendered =~ "phx-value-event_click_column_index=&quot;0&quot;"
    assert rendered =~ "phx-value-event_click_current_direction=&quot;desc&quot;"
    assert rendered =~ "phx-value-event_click_direction=&quot;asc&quot;"
    assert rendered =~ "phx-value-event_click_selection_mode=&quot;single&quot;"
    assert rendered =~ "phx-value-event_click_row_id=&quot;0&quot;"
    assert rendered =~ "phx-value-event_click_row_index=&quot;0&quot;"
  end

  test "renders form builders with change and submit bindings" do
    rendered =
      render_component(&WidgetRegistry.render/1,
        descriptor: %{
          id: "profile-form",
          kind: "form_builder",
          props: %{"submit_label" => "Save"},
          children: [
            %{
              id: "display-name",
              kind: "form_field",
              props: %{"label" => "Name", "name" => "name", "default" => "Pascal"}
            }
          ],
          signal_bindings: [
            %{
              event: "on_change",
              widget_id: "profile-form",
              widget_kind: "form_builder",
              payload: %{"intent" => "update_profile"}
            },
            %{
              event: "on_submit",
              widget_id: "profile-form",
              widget_kind: "form_builder",
              payload: %{"intent" => "save_profile"}
            }
          ]
        }
      )
      |> rendered_to_string()

    assert rendered =~ "phx-change=&quot;change&quot;"
    assert rendered =~ "phx-submit=&quot;submit&quot;"
    assert rendered =~ "phx-value-event_change_intent=&quot;update_profile&quot;"
    assert rendered =~ "phx-value-event_submit_intent=&quot;save_profile&quot;"
    assert rendered =~ "phx-value-event_change_form_id=&quot;profile-form&quot;"
    assert rendered =~ "phx-value-event_change_field_count=&quot;1&quot;"
    assert rendered =~ "id=&quot;display-name&quot;"
    assert rendered =~ "name=&quot;name&quot;"
  end

  test "renders tree, viewport, split pane, and command palette interaction metadata" do
    rendered =
      render_component(&WidgetRegistry.render/1,
        descriptor: %{
          id: "workspace-root",
          kind: "vbox",
          props: %{},
          children: [
            %{
              id: "tree-node-1",
              kind: "tree_node",
              props: %{"label" => "Node 1", "expanded" => true},
              signal_bindings: [
                %{
                  event: "on_select",
                  widget_id: "tree-node-1",
                  widget_kind: "tree_node",
                  payload: %{"intent" => "select_node"}
                },
                %{
                  event: "on_toggle",
                  widget_id: "tree-node-1",
                  widget_kind: "tree_node",
                  payload: %{"intent" => "toggle_node"}
                }
              ],
              children: [%{id: "leaf", kind: "label", props: %{"text" => "Leaf"}}]
            },
            %{
              id: "viewport-1",
              kind: "viewport",
              props: %{"scroll_top" => 12, "scroll_left" => 4},
              signal_bindings: [
                %{
                  event: "on_scroll",
                  widget_id: "viewport-1",
                  widget_kind: "viewport",
                  payload: %{"intent" => "sync_scroll"}
                }
              ],
              children: [%{id: "copy", kind: "text", props: %{"content" => "Scrollable"}}]
            },
            %{
              id: "main-split",
              kind: "split_pane",
              props: %{"sizes" => [30, 70], "orientation" => "vertical"},
              signal_bindings: [
                %{
                  event: "on_resize_change",
                  widget_id: "main-split",
                  widget_kind: "split_pane",
                  payload: %{"intent" => "resize"}
                }
              ],
              children: [
                %{id: "left-pane", kind: "label", props: %{"text" => "Left"}},
                %{id: "right-pane", kind: "label", props: %{"text" => "Right"}}
              ]
            },
            %{
              id: "palette-1",
              kind: "command_palette",
              props: %{"query" => "dep", "active_command_id" => "deploy"},
              signal_bindings: [
                %{
                  event: "on_change",
                  widget_id: "palette-1",
                  widget_kind: "command_palette",
                  payload: %{"intent" => "update_query"}
                },
                %{
                  event: "on_submit",
                  widget_id: "palette-1",
                  widget_kind: "command_palette",
                  payload: %{"intent" => "submit_query"}
                }
              ],
              children: [
                %{
                  id: "deploy",
                  kind: "command",
                  props: %{"label" => "Deploy"},
                  signal_bindings: [
                    %{
                      event: "action",
                      widget_id: "deploy",
                      widget_kind: "command",
                      payload: %{
                        "intent" => "run_command",
                        "payload" => %{"command_id" => "deploy"}
                      }
                    }
                  ]
                }
              ]
            }
          ]
        }
      )
      |> rendered_to_string()

    assert rendered =~ "live-ui-tree__toggle"
    assert rendered =~ "phx-value-event_click_node_id=&quot;tree-node-1&quot;"
    assert rendered =~ "phx-value-event_click_expanded=&quot;true&quot;"
    assert rendered =~ "phx-value-event_click_next_expanded=&quot;false&quot;"
    assert rendered =~ "phx-value-event_click_child_count=&quot;1&quot;"
    assert rendered =~ "phx-value-event_click_selected=&quot;true&quot;"
    assert rendered =~ "phx-value-event_click_selected=&quot;false&quot;"
    assert rendered =~ "data-scroll-top=&quot;12&quot;"
    assert rendered =~ "data-live-ui-event=&quot;scroll&quot;"
    assert rendered =~ "LiveUi.Viewport"
    assert rendered =~ "data-pane-index=&quot;0&quot;"
    assert rendered =~ "flex: 0 0 30%"
    assert rendered =~ "data-live-ui-event=&quot;resize&quot;"
    assert rendered =~ "LiveUi.SplitPane"
    assert rendered =~ "phx-change=&quot;change&quot;"
    assert rendered =~ "phx-submit=&quot;submit&quot;"
    assert rendered =~ "data-active-command-id=&quot;deploy&quot;"
    assert rendered =~ "phx-value-event_click_command_id=&quot;deploy&quot;"
  end

  test "renders monitoring widgets with structured filter and process-select actions" do
    rendered =
      render_component(&WidgetRegistry.render/1,
        descriptor: %{
          id: "monitor-root",
          kind: "vbox",
          props: %{},
          children: [
            %{
              id: "logs",
              kind: "log_viewer",
              props: %{"filter" => "error", "lines" => ["error one"], "source" => "app.log"},
              signal_bindings: [
                %{
                  event: "on_change",
                  widget_id: "logs",
                  widget_kind: "log_viewer",
                  payload: %{"intent" => "filter_logs"}
                },
                %{
                  event: "action",
                  widget_id: "logs",
                  widget_kind: "log_viewer",
                  payload: %{"intent" => "refresh_logs"}
                }
              ]
            },
            %{
              id: "processes",
              kind: "process_monitor",
              props: %{
                "node" => "demo@127.0.0.1",
                "processes" => [%{"pid" => "#PID<0.10.0>", "name" => "worker"}]
              },
              signal_bindings: [
                %{
                  event: "on_process_select",
                  widget_id: "processes",
                  widget_kind: "process_monitor",
                  payload: %{"intent" => "select_process"}
                }
              ]
            }
          ]
        }
      )
      |> rendered_to_string()

    assert rendered =~ "Filter logs"
    assert rendered =~ "phx-value-event_change_intent=&quot;filter_logs&quot;"
    assert rendered =~ "phx-value-event_click_intent=&quot;refresh_logs&quot;"
    assert rendered =~ "data-live-ui-source=&quot;app.log&quot;"
    assert rendered =~ "demo@127.0.0.1"
    assert rendered =~ "phx-value-event_click_pid=&quot;#PID&amp;lt;0.10.0&amp;gt;&quot;"
    assert rendered =~ "phx-value-event_click_name=&quot;worker&quot;"
  end

  test "renders server-authoritative overlay state for composite widgets" do
    rendered =
      render_component(&WidgetRegistry.render/1,
        descriptor: %{
          id: "state-root",
          kind: "vbox",
          props: %{},
          children: [
            %{
              id: "tabs-1",
              kind: "tabs",
              props: %{"active_tab" => "details", "open" => true},
              children: [
                %{id: "summary", kind: "tab", props: %{"label" => "Summary"}},
                %{id: "details", kind: "tab", props: %{"label" => "Details"}}
              ]
            },
            %{
              id: "tree-node-1",
              kind: "tree_node",
              props: %{"label" => "Node 1", "expanded" => false, "selected" => true},
              children: []
            },
            %{
              id: "users-table",
              kind: "table",
              props: %{
                "columns" => [%{"key" => "name", "header" => "Name"}],
                "data" => [%{"id" => "user-1", "name" => "Pascal"}],
                "selected_row_id" => "user-1",
                "sort_column" => "name",
                "sort_direction" => "asc"
              },
              signal_bindings: [
                %{
                  event: "on_sort",
                  widget_id: "users-table",
                  widget_kind: "table",
                  payload: %{"intent" => "sort_rows"}
                },
                %{
                  event: "on_row_select",
                  widget_id: "users-table",
                  widget_kind: "table",
                  payload: %{"intent" => "select_row"}
                }
              ]
            },
            %{
              id: "palette-1",
              kind: "command_palette",
              props: %{"query" => "dep", "active_command_id" => "deploy", "open" => false},
              children: [%{id: "deploy", kind: "command", props: %{"label" => "Deploy"}}]
            },
            %{
              id: "processes",
              kind: "process_monitor",
              props: %{
                "selected_pid" => "#PID<0.10.0>",
                "processes" => [%{"pid" => "#PID<0.10.0>", "name" => "worker"}]
              },
              signal_bindings: [
                %{
                  event: "on_process_select",
                  widget_id: "processes",
                  widget_kind: "process_monitor",
                  payload: %{"intent" => "select_process"}
                }
              ]
            }
          ]
        }
      )
      |> rendered_to_string()

    assert rendered =~ "live-ui-tabs__tab is-active"
    assert rendered =~ "live-ui-tree__node is-selected"
    assert rendered =~ "aria-expanded=&quot;false&quot;"
    assert rendered =~ "data-selected-row-id=&quot;user-1&quot;"
    assert rendered =~ "live-ui-table__sort is-sorted"
    assert rendered =~ "live-ui-table__row is-selected"
    assert rendered =~ "is-closed"
    assert rendered =~ "data-open=&quot;false&quot;"
    assert rendered =~ "live-ui-process-monitor__process is-selected"
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
