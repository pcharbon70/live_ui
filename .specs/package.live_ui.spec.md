# LiveUi Package Contract

`live_ui` is the Phoenix LiveView adapter package for `unified-ui` screens and canonical `UnifiedIUR` trees.

The package should preserve the `UnifiedUi` design principle that the authored DSL and the runtime rendering pipeline are separate concerns. `unified-ui` owns DSL authoring and IUR generation. `live_ui` owns LiveView mounting, interpretation, rendering, event bridging, and widget-local state.

The package also needs an explicit compatibility story for the current gap between canonical `unified_iur` and `unified-ui` extension widgets. The canonical path and the DSL path should converge on one rendering contract.

```spec-meta
{
  "id": "package.live_ui",
  "kind": "package",
  "status": "draft",
  "surface": ["LiveUi"],
  "relationships": [
    {"kind": "depends_on", "target": "package.unified_ui"},
    {"kind": "depends_on", "target": "package.unified_iur"},
    {"kind": "relates_to", "target": "module.live_ui_host_integration"},
    {"kind": "relates_to", "target": "module.live_ui_screen_macro"},
    {"kind": "relates_to", "target": "module.live_ui_runtime"},
    {"kind": "relates_to", "target": "module.live_ui_iur_interpreter"},
    {"kind": "relates_to", "target": "module.live_ui_widget_system"},
    {"kind": "relates_to", "target": "module.live_ui_signal_bridge"}
  ]
}
```

## Requirements

```spec-requirements
[
  {
    "id": "live_ui.input.dual_pipeline",
    "statement": "When the package receives either a UnifiedUi DSL screen module or a canonical UnifiedIUR tree, the package shall route both inputs through one normalized LiveView rendering pipeline.",
    "priority": "must",
    "stability": "stable"
  },
  {
    "id": "live_ui.render.normalization_boundary",
    "statement": "When a UI source is rendered, the package shall preserve a boundary in which DSL compilation remains owned by unified-ui and LiveView interpretation remains owned by live_ui.",
    "priority": "must",
    "stability": "stable"
  },
  {
    "id": "live_ui.integration.host_mounted_library",
    "statement": "When the package is integrated into Phoenix, the package shall behave as a reusable library mounted inside a host application rather than requiring a standalone live_ui endpoint or app shell.",
    "priority": "must",
    "stability": "stable"
  },
  {
    "id": "live_ui.integration.hybrid_entrypoints",
    "statement": "When the package exposes host-facing rendering entrypoints, the package shall provide tiny manually authored screen-specific wrappers through use LiveUi.Screen for normal DSL screen mounting and a generic dynamic entrypoint for canonical UnifiedIUR or validated runtime-selected sources, while sharing one internal runtime engine.",
    "priority": "must",
    "stability": "stable"
  },
  {
    "id": "live_ui.widget.catalog.parity",
    "statement": "When the package renders the unified-ui catalog, the package shall support all canonical UnifiedIUR widgets and all unified-ui extension widgets required by the DSL.",
    "priority": "must",
    "stability": "stable"
  },
  {
    "id": "live_ui.event.loop.rebuild",
    "statement": "When a user interaction is accepted, the package shall encode the interaction as a concrete `%Jido.Signal{}`, rebuild the interpreted tree, and rely on LiveView diffing for DOM reconciliation.",
    "priority": "must",
    "stability": "stable"
  },
  {
    "id": "live_ui.state.separation",
    "statement": "While a screen is mounted, the package shall keep screen domain state separate from widget-local adapter state and make both available during rebuilds.",
    "priority": "must",
    "stability": "stable"
  }
]
```

## Scenarios

```spec-scenarios
[
  {
    "id": "live_ui.dsl_screen_mount",
    "given": ["a screen module that uses UnifiedUi.Dsl and UnifiedUi.ElmArchitecture"],
    "when": ["the screen is mounted in LiveView"],
    "then": ["the module is initialized, compiled to IUR, interpreted, and rendered through the same descriptor pipeline used for canonical IUR"],
    "covers": ["live_ui.input.dual_pipeline", "live_ui.render.normalization_boundary", "live_ui.event.loop.rebuild"]
  },
  {
    "id": "live_ui.canonical_iur_mount",
    "given": ["a canonical UnifiedIUR tree produced outside the DSL"],
    "when": ["the tree is mounted for rendering"],
    "then": ["the tree is interpreted and rendered without requiring a UnifiedUi DSL module"],
    "covers": ["live_ui.input.dual_pipeline", "live_ui.render.normalization_boundary"]
  },
  {
    "id": "live_ui.host_app_mount",
    "given": ["a Phoenix application that wants to embed live_ui under its own router and layout"],
    "when": ["the host mounts the library"],
    "then": ["the library runs inside the host application shell without requiring a standalone live_ui endpoint"],
    "covers": ["live_ui.integration.host_mounted_library"]
  },
  {
    "id": "live_ui.hybrid_entrypoint_usage",
    "given": ["a host app mounting a regular DSL screen and a separate admin preview route for canonical UnifiedIUR"],
    "when": ["the host integrates live_ui"],
    "then": ["tiny manually authored screen-specific wrappers are used for normal screens, the generic entrypoint is used for dynamic rendering, and both delegate to the same internal runtime engine"],
    "covers": ["live_ui.integration.hybrid_entrypoints", "live_ui.integration.host_mounted_library", "live_ui.input.dual_pipeline"]
  },
  {
    "id": "live_ui.extension_widget_roundtrip",
    "given": ["a unified-ui screen containing viewport, split_pane, canvas, or command_palette widgets"],
    "when": ["the screen is rendered and interacted with"],
    "then": ["the extension widgets remain first-class supported nodes in the rendering and event pipeline"],
    "covers": ["live_ui.widget.catalog.parity", "live_ui.event.loop.rebuild", "live_ui.state.separation"]
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
      "live_ui.input.dual_pipeline",
      "live_ui.render.normalization_boundary",
      "live_ui.integration.host_mounted_library",
      "live_ui.integration.hybrid_entrypoints",
      "live_ui.widget.catalog.parity",
      "live_ui.event.loop.rebuild",
      "live_ui.state.separation"
    ]
  },
  {
    "kind": "test_file",
    "target": "test/live_ui/architecture/package_contract_test.exs",
    "covers": [
      "live_ui.input.dual_pipeline",
      "live_ui.integration.host_mounted_library",
      "live_ui.integration.hybrid_entrypoints",
      "live_ui.widget.catalog.parity",
      "live_ui.event.loop.rebuild"
    ]
  },
  {
    "kind": "command",
    "target": "mix test test/live_ui/**/*_test.exs",
    "covers": [
      "live_ui.input.dual_pipeline",
      "live_ui.integration.host_mounted_library",
      "live_ui.integration.hybrid_entrypoints",
      "live_ui.widget.catalog.parity",
      "live_ui.event.loop.rebuild",
      "live_ui.state.separation"
    ]
  }
]
```
