# LiveUi Architecture

## Goal

`live_ui` should be a reusable Phoenix LiveView library mounted inside a host Phoenix application while also accepting canonical `../unified_iur` trees directly.

The project has two required input paths:

1. `UnifiedUi.Dsl` modules and `UnifiedUi.ElmArchitecture` screens.
2. Canonical `UnifiedIUR` structs or maps generated outside the DSL.

The architecture should keep those input paths separate until they converge on a single normalized descriptor tree used by the LiveView renderer.

## Design Principles

- Keep `unified-ui` responsible for DSL authoring and DSL-to-IUR compilation.
- Keep `live_ui` responsible for LiveView runtime, interpretation, rendering, and event bridging.
- Use one normalization boundary so DSL screens and canonical IUR produce the same rendering path.
- Keep server-side state authoritative even when JavaScript hooks are used for richer interactions.
- Support the full `unified-ui` widget catalog, including extension widgets that are not yet present in canonical `unified_iur`.
- Do not require `live_ui` to own a standalone Phoenix endpoint, router, asset bundle, or release.

## Host Integration

`live_ui` should expose a host-facing integration surface rather than behave like a standalone Phoenix application.

The recommended host-facing API should be hybrid:

- default path: screen-specific host LiveViews written manually as thin wrappers over a shared macro
- dynamic path: one generic LiveView for canonical `UnifiedIUR` or runtime-selected screen sources
- implementation path: one internal runtime engine shared by both

The host Phoenix application should be responsible for:

- mounting `live_ui` routes or components from its router
- providing layouts, auth plugs, session data, and endpoint configuration
- importing or registering `live_ui` JavaScript hooks in its own asset pipeline
- choosing how screen modules or canonical IUR inputs are routed into the mounted LiveView

`live_ui` should be responsible for:

- publishing mount helpers and route conventions
- publishing the `LiveUi.Screen` macro for screen-specific wrapper LiveViews
- publishing a JS hook manifest or entrypoint that host assets can register
- accepting host-provided session and runtime context without assuming a particular app shell
- keeping the runtime, interpreter, renderer, and signal bridge independent from host-specific business logic

## Proposed Module Map

### Host-facing integration

- `LiveUi`
  - Public API for library configuration and screen mounting helpers.
- `LiveUi.Screen`
  - Macro for defining a host-facing LiveView wrapper for one DSL screen module.
  - Public API shape: `use LiveUi.Screen, source: MyApp.SomeScreen`.
  - Performs source configuration validation and delegates runtime behavior to the shared engine.
- `LiveUi.Router`
  - Optional helper macro or helper functions for mounting screens from a host router.
- `LiveUi.Assets`
  - Exposes JS hook registration and any required static assets so the host app can import them into its own bundle.
- `LiveUi.Session`
  - Normalizes host session, assigns, and route params into runtime context for the mounted screen.

### Input adapters

- `LiveUi.Source.Dsl`
  - Accepts a screen module that uses `UnifiedUi.Dsl`.
  - Calls `init/1` and `update/2` on the screen module.
  - Uses `UnifiedUi.IUR.Builder.build/2` to derive the current IUR tree.
- `LiveUi.Source.IUR`
  - Accepts canonical `UnifiedIUR` structs or map-shaped payloads.
  - Optionally validates canonical schema markers.
  - Passes the input to the interpreter without requiring a DSL module.

### Normalization and interpretation

- `LiveUi.IUR.Dependency`
  - Validates canonical schema markers such as schema name, schema source, and version.
- `LiveUi.IUR.ValueNormalizer`
  - Canonicalizes map, list, tuple, and set values before descriptor generation.
- `LiveUi.IUR.Interpreter`
  - Accepts canonical `UnifiedIUR` nodes and `UnifiedUi` extension structs implementing `UnifiedIUR.Element`.
  - Produces a serializable descriptor tree with stable node ids, kinds, props, children, style data, and signal bindings.
  - Rejects unsupported node kinds explicitly instead of dropping them.

### LiveView runtime

- `LiveUi.Runtime.Model`
  - Stores source input, screen state, widget-local state, descriptor tree, signal bindings, errors, and render metadata.
- `LiveUi.Runtime`
  - Owns the deterministic rebuild cycle.
  - Rebuild sequence: current source -> IUR tree -> descriptor tree -> rendered assigns.
- `LiveUi.Live.Engine`
  - Internal generic LiveView runtime engine.
  - Mounts the runtime model using host-provided session and params, handles `phx-*` events and hook-originated events, rebuilds the descriptor tree, and reassigns the view.
- `LiveUi.Live.DynamicLive`
  - Public generic entry point for canonical `UnifiedIUR` and runtime-selected sources.
- host-defined wrapper LiveViews
  - Thin host-facing LiveViews that delegate to `LiveUi.Live.Engine` through `use LiveUi.Screen, source: MyApp.SomeScreen`.

### Rendering

- `LiveUi.WidgetRegistry`
  - Maps normalized widget kinds to renderer modules.
- `LiveUi.Components.Layouts`
  - Renders `vbox`, `hbox`, `viewport`, and `split_pane` containers.
- `LiveUi.Components.BasicWidgets`
  - Renders `text`, `button`, `label`, and `text_input`.
- `LiveUi.Components.DataViz`
  - Renders `gauge`, `sparkline`, `bar_chart`, and `line_chart`.
- `LiveUi.Components.Navigation`
  - Renders `menu`, `context_menu`, `tabs`, `tree_view`, and nested items.
- `LiveUi.Components.Feedback`
  - Renders `dialog`, `alert_dialog`, `toast`, and dialog buttons.
- `LiveUi.Components.Forms`
  - Renders `pick_list`, `form_builder`, and nested field descriptors.
- `LiveUi.Components.Extensions`
  - Renders `canvas`, `command_palette`, and any future `unified-ui` adapter-local extensions.

### Event and signal bridge

- `LiveUi.Signals.Encoder`
  - Converts LiveView events into stable UnifiedUi/Jido-compatible signal payloads.
- `LiveUi.Live.EventRouter`
  - Extracts descriptor metadata from `phx-value-*` payloads.
  - Accepts hook-originated payloads through the same normalization boundary.
  - Merges widget-local state changes before screen updates when needed.
- `LiveUi.WidgetState`
  - Stores server-authoritative UI-only state such as active tabs, tree expansion, table sort state, viewport scroll position, split percentages, command palette query, and toast/dialog visibility.

### Style and theme bridge

- `LiveUi.Style.Compiler`
  - Maps `UnifiedIUR.Style` values into CSS variables, semantic classes, and inline geometry where needed.
- `LiveUi.Style.Theme`
  - Bridges named styles and theme tokens from `unified-ui` into a LiveView-friendly CSS token system.

## Data Flow

### DSL path

1. A host-defined wrapper LiveView is written manually with `use LiveUi.Screen, source: MyApp.SomeScreen`.
2. `LiveUi.Session` normalizes host route params, session values, and assigns into runtime context.
3. `LiveUi.Source.Dsl` calls the screen `init/1` function.
4. `UnifiedUi.IUR.Builder.build/2` converts DSL state into IUR.
5. `LiveUi.IUR.Interpreter` normalizes the IUR into descriptor nodes and signal bindings.
6. `LiveUi.WidgetRegistry` resolves each descriptor node to a renderer component.
7. The shared engine emits HEEx from the descriptor tree.
8. User events are encoded back into UnifiedUi/Jido signals and routed to `update/2`.
9. The runtime rebuilds the tree and lets LiveView diff the DOM.

### Canonical IUR path

1. `LiveUi.Live.DynamicLive` or a dedicated component receives canonical `UnifiedIUR` input.
2. `LiveUi.Source.IUR` validates schema markers when present.
3. `LiveUi.IUR.Interpreter` normalizes the input into the same descriptor tree used by the DSL path.
4. Rendering and event handling proceed through the same registry and runtime layers.

## Entry Point Strategy

The public API should prefer screen-specific wrappers for normal host usage because they fit Phoenix conventions better:

- each screen gets an explicit route
- each screen can attach host-specific auth and layout rules
- the host app gets compile-time references to screen modules
- the wrappers stay tiny and explicit instead of depending on code generation

Recommended wrapper shape:

```elixir
defmodule MyAppWeb.CounterLive do
  use LiveUi.Screen, source: MyApp.CounterScreen
end
```

The macro should validate the `source` option explicitly so configuration failures are surfaced before a host route reaches runtime rendering.

## `LiveUi.Screen` V1 API

The `LiveUi.Screen` macro should stay intentionally narrow in v1.

Supported macro options:

- `source: MyApp.SomeScreen`
  - required
  - must be a screen module reference, not a registry key, string, or runtime-selected value

Supported optional callbacks on the wrapper module:

- `liveui_context(params, session, socket)`
  - returns additional runtime context merged into the mount context
- `liveui_source_opts(params, session, socket)`
  - returns the option list passed into the source screen initialization path

Unsupported wrapper overrides:

- `mount/3`
- `render/1`
- `handle_event/3`

Those behaviors should remain owned by the shared engine so all wrapper modules stay uniform.

The dynamic generic entry point should remain available for:

- canonical `UnifiedIUR` rendering
- admin or preview tools
- runtime-selected screens from a validated registry

The generic engine should stay internal so that both public entry styles share one runtime implementation.
The dynamic path, not `LiveUi.Screen`, should carry any runtime-selected source registry concerns.

## Widget Support Strategy

### Canonical `unified_iur` widgets

- layouts: `vbox`, `hbox`
- basic widgets: `text`, `button`, `label`, `text_input`
- data visualization: `gauge`, `sparkline`, `bar_chart`, `line_chart`
- structured widgets: `table`, `column`
- navigation: `menu`, `menu_item`, `context_menu`, `tabs`, `tab`, `tree_view`, `tree_node`
- feedback: `dialog`, `dialog_button`, `alert_dialog`, `toast`
- advanced inputs: `pick_list`, `pick_list_option`, `form_builder`, `form_field`

### `unified-ui` extension widgets

These exist in `unified-ui` but are not currently part of canonical `unified_iur`:

- `viewport`
- `split_pane`
- `canvas`
- `command`
- `command_palette`

The interpreter should accept these extension structs because they already implement `UnifiedIUR.Element`. The registry should treat them as first-class supported kinds rather than second-class fallbacks.

## LiveView State Model

The LiveView process should keep three state buckets separate:

- `screen_state`
  - Domain state owned by the screen module.
- `widget_state`
  - UI-only state owned by the LiveView adapter.
- `view_state`
  - The interpreted descriptor tree, event bindings, style tokens, and render metadata.

That split lets `live_ui` preserve transient interaction state without polluting screen state with adapter concerns.

## Stateful Widget Notes

- `table`
  - Server-authoritative sort key, sort direction, row selection, and pagination or viewport position.
- `tabs`
  - Server-authoritative active tab id.
- `tree_view`
  - Server-authoritative expanded node ids and selected node.
- `menu` and `context_menu`
  - Open and active item state may use hooks for focus handling, but final selection state remains server-authoritative.
- `dialog`, `alert_dialog`, and `toast`
  - Visibility and dismissal events are server-authoritative.
- `viewport`
  - Scroll offsets live in `widget_state` and may be synchronized through throttled hooks.
- `split_pane`
  - Divider position lives in `widget_state` and is updated from drag events.
- `command_palette`
  - Query text, active command, and visibility live in `widget_state`.
- `canvas`
  - Render through a recording drawing context that converts draw callbacks into serializable SVG or drawing operations.

## Rendering Strategy

- Prefer function components for pure renderers.
- Use `Phoenix.LiveComponent` only when a widget has meaningful local lifecycle or focused diff boundaries.
- Use JS hooks as a first-class integration tool for interactions that need pointer capture, measurement, keyboard coordination, scroll synchronization, or rich drawing support.
- Do not make correctness depend solely on client-side JS. Hooks may improve fidelity, but server-authoritative rendering and state remain the baseline contract.

## Error Handling

- Invalid canonical schema markers should produce typed validation errors.
- Unsupported widget kinds should produce explicit interpreter failures.
- Rendering failures should surface deterministic error shells rather than crashing the LiveView process.
- Event payload validation should reject malformed client input before signal dispatch.

## Testing Strategy

- Unit tests for source adapters, schema validation, value normalization, interpreter output, and signal encoding.
- Component tests for each widget family.
- LiveView integration tests for event round-trips and rebuild behavior.
- Host app integration tests for router mounting, session propagation, and JS hook registration.
- Wrapper-vs-dynamic parity tests proving both public entry styles delegate to the same runtime engine.
- Golden descriptor tests for DSL and canonical IUR inputs that should render identically.
- Focused regression tests for extension widgets: `viewport`, `split_pane`, `canvas`, and `command_palette`.

## Initial Build Order

1. Runtime model and `ScreenLive` loop.
2. IUR interpreter and schema validation.
3. Basic layouts and widgets.
4. Signal encoder and standard event round-trip.
5. Tables, tabs, tree view, and pick list.
6. Dialog, toast, and form builder.
7. `viewport`, `split_pane`, `command_palette`, and `canvas`.
8. Styling, theming, and enhanced hooks.
