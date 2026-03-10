# LiveUi Host Integration

The host integration subject defines how `live_ui` is mounted inside another Phoenix application.

This subject is the public library boundary for routing, session/context propagation, and JS hook asset registration. It should make `live_ui` easy to adopt without requiring a standalone Phoenix app shell.

```spec-meta
{
  "id": "module.live_ui_host_integration",
  "kind": "module",
  "status": "draft",
  "surface": ["LiveUi", "LiveUi.Router", "LiveUi.Assets", "LiveUi.Session"],
  "relationships": [
    {"kind": "depends_on", "target": "package.live_ui"},
    {"kind": "relates_to", "target": "module.live_ui_screen_macro"},
    {"kind": "relates_to", "target": "module.live_ui_runtime"},
    {"kind": "relates_to", "target": "module.live_ui_signal_bridge"}
  ]
}
```

## Requirements

```spec-requirements
[
  {
    "id": "live_ui_host.mounts_in_host_router",
    "statement": "When a host Phoenix application integrates live_ui, the library shall expose mount helpers or route conventions that allow screens to be mounted from the host router without requiring a standalone endpoint.",
    "priority": "must",
    "stability": "stable"
  },
  {
    "id": "live_ui_host.prefers_screen_wrappers",
    "statement": "When a host mounts a regular UnifiedUi DSL screen, the integration layer shall support tiny manually authored screen-specific LiveView wrappers declared with use LiveUi.Screen, source: <screen module>.",
    "priority": "must",
    "stability": "stable"
  },
  {
    "id": "live_ui_host.supports_dynamic_entrypoint",
    "statement": "When a host needs to render canonical UnifiedIUR or a validated runtime-selected screen source, the integration layer shall support a generic dynamic LiveView entrypoint alongside the screen-specific wrappers.",
    "priority": "must",
    "stability": "stable"
  },
  {
    "id": "live_ui_host.accepts_host_session_context",
    "statement": "When a mounted screen starts, the host integration layer shall normalize host session data, route params, and assigns into runtime context for the LiveUi runtime.",
    "priority": "must",
    "stability": "stable"
  },
  {
    "id": "live_ui_host.exposes_hook_assets",
    "statement": "When advanced widgets require JavaScript hooks, the library shall expose hook registration or asset entrypoints that the host application can import into its own bundle.",
    "priority": "must",
    "stability": "stable"
  },
  {
    "id": "live_ui_host.respects_host_shell",
    "statement": "While a screen is mounted inside a host application, the integration layer shall preserve host ownership of layouts, authentication, endpoint configuration, and release topology.",
    "priority": "must",
    "stability": "stable"
  },
  {
    "id": "live_ui_host.shared_engine_across_entrypoints",
    "statement": "When screen-specific wrappers and the generic dynamic entrypoint are both used, the integration layer shall delegate both entry styles to the same internal runtime engine.",
    "priority": "must",
    "stability": "stable"
  }
]
```

## Scenarios

```spec-scenarios
[
  {
    "id": "live_ui_host.router_mount",
    "given": ["a host Phoenix router that wants to expose a live_ui screen route"],
    "when": ["the host mounts the library"],
    "then": ["the screen is reachable through the host router via a tiny manually authored wrapper LiveView without a separate live_ui endpoint"],
    "covers": ["live_ui_host.mounts_in_host_router", "live_ui_host.prefers_screen_wrappers", "live_ui_host.respects_host_shell"]
  },
  {
    "id": "live_ui_host.session_normalization",
    "given": ["host session data, route params, and assigns"],
    "when": ["a live_ui screen mounts"],
    "then": ["the data is normalized into runtime context before the runtime initializes the screen"],
    "covers": ["live_ui_host.accepts_host_session_context"]
  },
  {
    "id": "live_ui_host.dynamic_mount",
    "given": ["a host route used for canonical UnifiedIUR preview or runtime-selected validated sources"],
    "when": ["the host mounts the generic dynamic entrypoint"],
    "then": ["the route renders through the generic entrypoint without replacing the screen-specific wrapper model for ordinary screens"],
    "covers": ["live_ui_host.supports_dynamic_entrypoint", "live_ui_host.mounts_in_host_router"]
  },
  {
    "id": "live_ui_host.shared_runtime_engine",
    "given": ["a manually authored screen-specific wrapper route and a generic dynamic route"],
    "when": ["both are exercised in the same host application"],
    "then": ["both entry styles delegate to the same internal runtime engine"],
    "covers": ["live_ui_host.shared_engine_across_entrypoints", "live_ui_host.prefers_screen_wrappers", "live_ui_host.supports_dynamic_entrypoint"]
  },
  {
    "id": "live_ui_host.hook_registration",
    "given": ["a host application rendering split_pane, viewport, command_palette, or canvas widgets"],
    "when": ["the host imports live_ui assets"],
    "then": ["the host can register the library's JS hooks in its own bundle and keep the widgets interactive"],
    "covers": ["live_ui_host.exposes_hook_assets", "live_ui_host.respects_host_shell"]
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
      "live_ui_host.mounts_in_host_router",
      "live_ui_host.prefers_screen_wrappers",
      "live_ui_host.supports_dynamic_entrypoint",
      "live_ui_host.accepts_host_session_context",
      "live_ui_host.exposes_hook_assets",
      "live_ui_host.respects_host_shell",
      "live_ui_host.shared_engine_across_entrypoints"
    ]
  },
  {
    "kind": "test_file",
    "target": "test/live_ui/host/router_integration_test.exs",
    "covers": ["live_ui_host.mounts_in_host_router", "live_ui_host.prefers_screen_wrappers", "live_ui_host.supports_dynamic_entrypoint", "live_ui_host.respects_host_shell"]
  },
  {
    "kind": "test_file",
    "target": "test/live_ui/host/session_test.exs",
    "covers": ["live_ui_host.accepts_host_session_context"]
  },
  {
    "kind": "test_file",
    "target": "test/live_ui/host/entrypoint_parity_test.exs",
    "covers": ["live_ui_host.shared_engine_across_entrypoints"]
  },
  {
    "kind": "test_file",
    "target": "test/live_ui/assets/hooks_test.exs",
    "covers": ["live_ui_host.exposes_hook_assets"]
  }
]
```
