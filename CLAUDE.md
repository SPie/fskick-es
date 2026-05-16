# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Initial setup
mix setup

# Start dev server
mix phx.server
# or with IEx
iex -S mix phx.server

# Run all tests
mix test

# Run a single test file
mix test test/fskick_web/controllers/page_controller_test.exs

# Run previously failed tests
mix test --failed

# Pre-commit check (compile with warnings-as-errors, remove unused deps, format, test)
mix precommit

# Database
mix ecto.setup       # create + migrate + seed
mix ecto.reset       # drop + setup
mix ecto.gen.migration migration_name_using_underscores

# Event store
mix event_store.setup   # create + init
mix event_store.reset   # drop + setup

# Asset build (dev)
mix assets.build
```

The `precommit` alias runs in `:test` env. Run it before finishing any change set.

## Architecture

This is a Phoenix 1.8 + LiveView application backed by PostgreSQL via Ecto.

**Key namespaces:**
- `Fskick` — business logic / context modules (lives under `lib/fskick/`)
- `FskickWeb` — web layer: router, controllers, LiveViews, components (lives under `lib/fskick_web/`)

**Web layer wiring (`lib/fskick_web.ex`):**
- `use FskickWeb, :live_view` — sets up LiveView with html_helpers (imports `FskickWeb.CoreComponents`, aliases `FskickWeb.Layouts` and `Phoenix.LiveView.JS`)
- `use FskickWeb, :html` — for function component modules
- `use FskickWeb, :controller` — for controllers
- All templates have `FskickWeb.CoreComponents` and `FskickWeb.Layouts` available without explicit aliasing

**CQRS/Event Sourcing:** Commanded (`~> 1.4`) with `commanded_eventstore_adapter` and `eventstore`. The Commanded application is `Fskick.App` (`lib/fskick/app.ex`, `use Commanded.Application`). The event store is `Fskick.EventStore` (`lib/fskick/event_store.ex`, `use EventStore`). Both are started as supervised children in `Fskick.Application`. Config lives under `config :fskick, Fskick.App` (event store adapter) and `config :fskick, event_stores: [Fskick.EventStore]`.

**Context layout for CQRS entities** (established by `Fskick.Players`):

- `lib/fskick/<context>.ex` — public API. Write side dispatches commands via `Fskick.App.dispatch/1`; read side queries the projection through `Fskick.Repo`.
- `lib/fskick/<context>/commands/<verb>_<entity>.ex` — command as an embedded Ecto schema with `new/1` returning `{:ok, command} | {:error, changeset}`. Structural validation lives here: presence, trimming/formatting, and cross-aggregate uniqueness checks against the read model.
- `lib/fskick/<context>/aggregates/<entity>.ex` — aggregate root with `execute/2` + `apply/2`. Enforces state-dependent invariants only (e.g. `{:error, :already_created}`); returns events on success.
- `lib/fskick/<context>/events/<past_tense>.ex` — plain struct with `@derive Jason.Encoder`.
- `lib/fskick/<context>/projectors/<entity>.ex` — `use Commanded.Projections.Ecto` with an explicit `name:` string; writes the read-model row via `Ecto.Multi`.
- `lib/fskick/<context>/<entity>.ex` — read-model `Ecto.Schema` with `@primary_key {:id, :binary_id, autogenerate: false}`. Written only by the projector; never used for casting user input.

The context generates the aggregate id (`Ecto.UUID.generate/0`) before dispatching, then polls `Repo.get/2` until the projection catches up (timeout returns `{:error, :projection_timeout}`) so callers receive a consistent `{:ok, struct}`.

Aggregates are routed in `Fskick.Router` with `identify/2` (prefix per aggregate, e.g. `prefix: "player-"`) and `dispatch/2`.

Mix tasks for write-side operations live at `lib/mix/tasks/fskick.<context>.<verb>.ex` (e.g. `mix fskick.players.new "Alice"`) and call into the context, not the command/aggregate directly.

**Player concept:** a Player is the canonical participant entity in fskick. Identity is a server-generated `binary_id` (UUID); the only intrinsic attribute today is a `name`, which must be unique across all players. Players are created exactly once — the aggregate rejects re-creation with `{:error, :already_created}` — and there are no update or delete operations yet. The read-model row in `players` is the lookup surface for the rest of the app (e.g. uniqueness checks during command validation); the aggregate stream `player-<uuid>` is the source of truth.

**HTTP stack:** Bandit (not Cowboy)

**Asset pipeline:** esbuild (JS) + Tailwind v4 (CSS), both run as watchers in dev. Only `app.js` and `app.css` bundles are supported — all vendor deps must be imported into those files, never via external `<script src>` or `<link href>` tags.

**CSS:** Tailwind v4 with this exact import block in `assets/css/app.css`:
```css
@import "tailwindcss" source(none);
@source "../css";
@source "../js";
@source "../../lib/fskick_web";
```
Never use `@apply`. Never use a `tailwind.config.js`.

**Email:** Swoosh with Local adapter in dev (preview at `/dev/mailbox`). Use `Req` for HTTP requests — never `:httpoison`, `:tesla`, or `:httpc`.

## Phoenix 1.8 / LiveView rules

- All LiveView templates must begin with `<Layouts.app flash={@flash} ...>` wrapping all content
- Routes that need `current_scope` must be inside the correct `live_session` block; never fix missing-assign errors by adding assigns ad-hoc
- Icons: always `<.icon name="hero-x-mark" />`, never `Heroicons` modules
- Forms: always `to_form/2` → `<.form for={@form}>` → `<.input field={@form[:field]}>`. Never pass a raw changeset to a template
- Collections in LiveViews: always use streams (`stream/3`, `stream_insert/3`, `stream_delete/3`); never assign plain lists for rendered collections
- Links/navigation: `<.link navigate={href}>` / `<.link patch={href}>`, `push_navigate`, `push_patch`. Never `live_redirect` or `live_patch`
- HEEx interpolation: `{...}` in tag attributes and simple values; `<%= ... %>` for block constructs (`if`, `case`, `for`) in tag bodies
- HEEx comments: `<%!-- comment --%>`
- Colocated JS hooks: use `<script :type={Phoenix.LiveView.ColocatedHook} name=".HookName">` (name must start with `.`); never `<script>` tags in templates
- `<.flash_group>` only inside `layouts.ex` — forbidden everywhere else

## Elixir pitfalls to avoid

- Lists have no index access syntax — use `Enum.at/2` or pattern matching
- Rebind `if`/`case`/`cond` results outside the block, not inside
- Never nest multiple modules in one file
- Never use map access syntax (`struct[:field]`) on plain structs — use `struct.field` or `Ecto.Changeset.get_field/2`
- Never use `String.to_atom/1` on user input
- Predicate functions end in `?`, not `is_` prefix
- Fields set programmatically (e.g. `user_id`) must not appear in `cast/3` calls

## Testing

- Test helpers: `ConnCase` (`test/support/conn_case.ex`), `DataCase` (`test/support/data_case.ex`)
- LiveView tests: `Phoenix.LiveViewTest` + `LazyHTML` for assertions
- Always use `start_supervised!/1` for process lifecycle in tests
- Avoid `Process.sleep/1`; use `Process.monitor/1` + `assert_receive {:DOWN, ...}` to wait for process exit
- Use `:sys.get_state/1` to synchronize before next call
- Assert on element presence/structure (`has_element?`, `element/2`), not raw HTML strings
