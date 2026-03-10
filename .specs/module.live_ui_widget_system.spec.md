# LiveUi Widget System

The widget system subject renders normalized descriptor nodes into HEEx through a registry of widget and layout renderer modules.

It is responsible for complete catalog coverage, style application, and the correct handling of stateful composite widgets.

```spec-meta
{
  "id": "module.live_ui_widget_system",
  "kind": "module",
  "status": "draft",
  "surface": ["LiveUi.WidgetRegistry", "LiveUi.Components.Layouts", "LiveUi.Components.BasicWidgets", "LiveUi.Components.DataViz", "LiveUi.Components.Navigation", "LiveUi.Components.Feedback", "LiveUi.Components.Forms", "LiveUi.Components.Extensions", "LiveUi.Style.Compiler"],
  "relationships": [
    {"kind": "depends_on", "target": "package.live_ui"},
    {"kind": "depends_on", "target": "module.live_ui_iur_interpreter"},
    {"kind": "governed_by", "target": "policy.live_ui_governance"},
    {"kind": "governed_by", "target": "policy.live_ui_conformance"},
    {"kind": "relates_to", "target": "module.live_ui_signal_bridge"}
  ]
}
```

```spec-governance
{
  "owner": "team.live_ui",
  "criticality": "high",
  "primary_plane": "rendering",
  "change_rules": [
    {
      "id": "widget_system_changes_require_interpreter_alignment",
      "when": {
        "change_types": ["behavior_shape"]
      },
      "requires": [
        {"subject_ids": ["module.live_ui_iur_interpreter", "module.live_ui_signal_bridge"]},
        {"verification_kinds": ["test_file"]}
      ],
      "severity": "error"
    }
  ],
  "approval": {
    "required": true,
    "roles": ["maintainer"]
  },
  "gates": [
    {
      "id": "local_spec_check",
      "kind": "mix_task",
      "target": "mix spec.check",
      "mode": "required"
    }
  ]
}
```

## Requirements

```spec-requirements
[
  {
    "id": "live_ui_widgets.registry.covers_all_kinds",
    "statement": "When a normalized descriptor kind is emitted by the interpreter, the widget system shall resolve that kind through a registry that covers every canonical UnifiedIUR widget and every required unified-ui extension widget.",
    "priority": "must",
    "stability": "stable"
  },
  {
    "id": "live_ui_widgets.render.stateless_vs_stateful",
    "statement": "When a widget is rendered, the widget system shall use pure function components for stateless widgets and shall reserve LiveComponents or hooks for widgets whose interaction model requires local lifecycle or measurement support.",
    "priority": "should",
    "stability": "stable"
  },
  {
    "id": "live_ui_widgets.hooks.first_class_for_advanced_interactions",
    "statement": "When widget interactions require measurement, drag, pointer capture, keyboard coordination, scroll synchronization, or rich drawing support, the widget system shall support JavaScript hooks as a first-class adapter tool while keeping server state authoritative.",
    "priority": "must",
    "stability": "stable"
  },
  {
    "id": "live_ui_widgets.styles.map_to_css_tokens",
    "statement": "When a descriptor includes UnifiedIUR style or layout metadata, the widget system shall map that metadata into stable CSS classes or variables and use inline style only for dynamic geometry that cannot be expressed semantically.",
    "priority": "must",
    "stability": "stable"
  },
  {
    "id": "live_ui_widgets.charts.and_canvas.server_correctness",
    "statement": "When chart or canvas widgets are rendered, the widget system shall provide a server-correct rendering path that remains functional without client-side JavaScript.",
    "priority": "must",
    "stability": "stable"
  },
  {
    "id": "live_ui_widgets.overlay.and_composite.behavior",
    "statement": "When composite or overlay widgets such as tables, tabs, tree views, dialogs, toasts, viewports, split panes, and command palettes are rendered, the widget system shall preserve their server-authoritative state and expose the interactions needed by the signal bridge.",
    "priority": "must",
    "stability": "stable"
  }
]
```

## Scenarios

```spec-scenarios
[
  {
    "id": "live_ui_widgets.renders_basic_catalog",
    "given": ["descriptor nodes for text, button, label, text_input, vbox, and hbox"],
    "when": ["the widget registry resolves the nodes"],
    "then": ["each node is rendered through the mapped layout or widget renderer"],
    "covers": ["live_ui_widgets.registry.covers_all_kinds", "live_ui_widgets.render.stateless_vs_stateful", "live_ui_widgets.styles.map_to_css_tokens"]
  },
  {
    "id": "live_ui_widgets.renders_server_correct_canvas",
    "given": ["a canvas descriptor with recorded drawing operations"],
    "when": ["the canvas renderer emits markup"],
    "then": ["the output remains correct without relying on client-side JavaScript for baseline rendering and may layer hooks on top for richer interaction"],
    "covers": ["live_ui_widgets.charts.and_canvas.server_correctness", "live_ui_widgets.hooks.first_class_for_advanced_interactions", "live_ui_widgets.registry.covers_all_kinds"]
  },
  {
    "id": "live_ui_widgets.renders_stateful_composites",
    "given": ["descriptor nodes for table, tabs, tree_view, viewport, split_pane, dialog, toast, or command_palette"],
    "when": ["the nodes are rendered and interacted with"],
    "then": ["the renderers preserve server-authoritative widget state and expose stable interaction hooks where richer behavior is needed"],
    "covers": ["live_ui_widgets.overlay.and_composite.behavior", "live_ui_widgets.render.stateless_vs_stateful", "live_ui_widgets.hooks.first_class_for_advanced_interactions"]
  }
]
```

## Verification

```spec-verification
[
  {
    "kind": "doc",
    "target": "docs/architecture.md",
    "covers": [
      "live_ui_widgets.registry.covers_all_kinds",
      "live_ui_widgets.render.stateless_vs_stateful",
      "live_ui_widgets.hooks.first_class_for_advanced_interactions",
      "live_ui_widgets.styles.map_to_css_tokens",
      "live_ui_widgets.charts.and_canvas.server_correctness",
      "live_ui_widgets.overlay.and_composite.behavior"
    ]
  },
  {
    "kind": "test_file",
    "target": "test/live_ui/widgets/widget_registry_test.exs",
    "covers": ["live_ui_widgets.registry.covers_all_kinds"]
  },
  {
    "kind": "test_file",
    "target": "test/live_ui/components/widget_rendering_test.exs",
    "covers": [
      "live_ui_widgets.render.stateless_vs_stateful",
      "live_ui_widgets.hooks.first_class_for_advanced_interactions",
      "live_ui_widgets.styles.map_to_css_tokens",
      "live_ui_widgets.overlay.and_composite.behavior"
    ]
  },
  {
    "kind": "test_file",
    "target": "test/live_ui/components/canvas_and_chart_test.exs",
    "covers": ["live_ui_widgets.charts.and_canvas.server_correctness"]
  }
]
```
