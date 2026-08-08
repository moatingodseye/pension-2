# Archon — Design, Style & Code Rules

Portable, self-contained rule sheet for an agent working on **Archon** (or an
Archon-style Dart project) on a fresh machine. **Everything needed is in this
file** — no live database or network access is required to understand and apply
these rules. These rules are **mandatory, not suggestions**.

## Where these rules come from

This file already contains the complete rule set — you do not need to fetch
anything. For reference, there are three authoritative sources, in priority
order:

1. **The rule table in the live database** — the canonical, versioned rule set.
   Section 1 below is a full transcription of that table as of 2026-06-08
   (every row, with text, scope, and agent note). If you have access to the
   Archon repo, you can re-sync it via the CLI (never curl the live API by hand):

   ```bash
   dart run tool/bin/archon.dart rule ls --json   # full raw list, all scopes
   ```

   But the snapshot in §1 stands alone — no fetch is needed to apply the rules.

2. **`CLAUDE.md`** at the repo root — the same rules in prose, plus a few
   conventions not yet rowed into the DB.

3. **Architecture conventions** established by recent tickets (#376, #389,
   #393/#394, #396) and the design plans under `plan/`. These are real,
   enforced rules but are **not yet codified as DB rows** — Section 4.

### Rule scope

Every rule has a scope. Apply only those that match your project:

| Scope | Applies to | In this doc |
|-------|-----------|-------------|
| **Global** | every project, every language | always apply |
| **Dart project-type** (`projecttypeid=1`) | any Dart project | apply when writing Dart |
| **Archon project** (`projectid=1`) | the Archon repo specifically | apply in this repo |

Language rules (e.g. "no `dynamic`") are **project-type-scoped, not global** —
they bind Dart work, not a Delphi project (`projecttypeid=6`).

---

## 1. Canonical rules (from the DB rule table)

Format: `#id [Category | Scope] Title` → rule text. *Agent note* is the
condensed instruction injected into sub-agent prompts.

### Process — read this before any other rule

- **#0 [Global] The design documentation is the source of truth, and is kept up
  to date at all times.** Design docs are not a record written afterwards; they
  are the specification the code answers to. So a change request is worked in
  this order, always:
  1. **Update the design** to describe the change — before writing code. If the
     design and the request disagree, the design is what gets corrected first.
  2. **Build** what the design now says.
  3. **Mark it off in the design as implemented** — the design carries its own
     status, so anyone reading it knows what is live and what is still intended.

  A design left describing an architecture the code abandoned is worse than no
  design: the next reader trusts it. Never defer the design update to the end of
  a piece of work, and never let an implementation plan quietly become the real
  spec — a plan is how to get there, the design is what is true.

  **An implementation shortcut is NEVER written into the design as a decision.**
  This is the subtle breach, and it is how a design stops being true without
  anyone noticing. Code takes a shortcut — a lookup by name instead of by type, a
  cache that is never invalidated, a case left unhandled. Someone later describes
  what the code does *in the design*, and from then on the shortcut reads as an
  agreed choice. It gets defended in review. It gets cited back to the owner as
  "by design" — the exact words used to justify a defect to the person who never
  agreed to it. The design states what is INTENDED; where the code falls short,
  that is recorded as **a defect being carried, with its cost**, and never as a
  decision. If it truly is a decision, it is the owner's to make, in the design,
  before the code (#30).

  *Agent note: before editing code for a change request, open the design doc and
  update it. After the work lands, go back and mark the section implemented.
  If you changed the architecture mid-build, the design is updated in the SAME
  commit — never left stale behind you. Before writing "by design" or "out of
  scope by design" anywhere, find where the design SAYS it. If the only evidence
  is a code comment or a commit message, it is not a design — say "not built
  yet" or "a defect we are carrying", and say what it costs.*

- **#30 [Global] Deferring, parking, ignoring or closing a finding is the OWNER'S
  call, never the agent's.** When a review — human, agent, or tool — produces a
  finding, the agent's job is to **surface it and recommend**, then wait for the
  decision. It does not sort findings into "worth raising" and "not".

  This holds however the discarding is dressed up: a "minor" recorded in a ledger,
  an item "parked with a ruling", a reviewer's "close, no action" accepted on the
  owner's behalf, a follow-up filed into a doc, or a severity quietly downgraded.
  All of those are the same act — removing a choice that was not the agent's to
  remove — and doing it inside work that looks like progress is what makes it
  hard to notice.

  It also compounds. A finding the agent discards is one the owner never sees, so
  the error is invisible by construction rather than merely unlogged.

  **This overrides process guidance to the contrary.** Several agent workflows
  explicitly permit a controller to triage minors, park findings at a retry cap,
  or defer to a later review. Where they do, this rule wins.

  **SCOPE IS THE SAME DECISION, and it is the owner's alone.** What is in scope,
  what is out of scope, what is deferred to a later phase, what is "not worth
  doing", what is "good enough for now" — none of these are ever the agent's to
  settle. The agent may **recommend** a boundary and must state what each option
  costs; it may not **declare** one.

  This binds the agent's own documents most of all, because that is where the
  breach hides. A design or plan section headed "Out of scope", "Not in this
  design", "Deferred", or "Future work" reads as settled to every later reader —
  and if an agent wrote it, nobody decided it. Such a section is legitimate only
  when it records a decision the owner actually made (say so, and when), or when
  it is explicitly marked as a RECOMMENDATION AWAITING DECISION. The same applies
  to the phrase "out of scope" in conversation: it announces a ruling the agent
  has no standing to make.

  *Agent note: present every finding with its severity and your recommended call,
  then stop and wait. If something is genuinely blocking and the owner is
  unreachable, take the safe action and say so immediately, flagged as needing
  review — never record it as settled. Before writing "out of scope", "deferred"
  or "future work" in a doc or a reply, either cite the owner's decision or label
  it as your recommendation and ask.*

### Naming

- **#1 [Global] No redundant pluralisation.** Variables that are by definition
  already plural are not pluralised: `array`, `table`, `list`, `map`. A list's
  property is `item`, not `items`; `item[0]`, not `items[0]`.
- **#8 [Dart] Specific widget/class names.** Names must be specific to their
  domain: `TicketTypeBadge` not `TypeBadge`, `TicketStatusPill` not `StatusPill`.
- **#9 [Dart] Use `kind`, not `type`, for reserved-word clashes.**
- **#10 [Global] Soft delete is `delete`/`undelete`.** Archive and restore
  operations are named `delete` and `undelete` (it is soft delete, not physical
  removal).
- **#18 [Global] Table/column names: lowercase, singular, no underscores.**
- **#21 [Dart] Flat-lowercase Dart filenames.** No underscores in the name body
  (`sqlitetypemap.dart`, `ticketdetail.dart`). Only the `_test` suffix uses an
  underscore (`archoncli_test.dart`). Older paths still have underscores; new
  code follows the flat style.
- **#29 [Global] Short codes and abbreviations are unique across the estate.**
  Any mnemonic short form — an `EntityToken` abbreviation, a table alias, a log
  prefix, a UI badge code — must be distinct from every other one in use. Two
  entities sharing a short code is confusing at best and misleading at worst,
  and the reader has no way to tell which one they are looking at.

  Uniqueness holds even when nothing currently reads the value. An unread field
  is the dangerous case, not the safe one: nothing can detect the clash, so it
  survives until the day someone puts it in a log line and two unrelated rows
  start looking identical.
  *Agent note: before minting a short code, grep the estate for it. When a code
  is picked while its table is not yet live, fix a clash immediately — identity
  is frozen for life the moment it ships (#20), and free to change until then.*

### Style / Types

- **#7 [Dart] No `dynamic`, `Object?`, or untyped maps.** Never use `dynamic`,
  `Object?`, or `Map<String, Object?>`. Define a typed class or value-type
  wrapper. `Object?` is allowed **only** in extreme, tightly-scoped cases where
  no typed class can suffice — and `Map<String, Object?>` is legitimate only as
  the *output* of a `toJson` at a serialisation boundary.
  *Agent note: before writing any map-shaped value or untyped cast, define a
  typed model. Grep your own diff for `Object?` / `dynamic` / `Map<` before
  committing.*
- **#27 [Dart] No `var` — always an explicit type.** Every variable is declared
  with its proper type (`int count = 0;`, `final List<Rule> rule = fetchRules();`),
  never `var` (nor a bare inferred `final x = …`). The written type is the
  readable, greppable contract at the exact point it matters; inference hides it.
  Applies to locals, fields, loop variables, and closure parameters.
  *Agent note: grep your diff for `\bvar\b` (and `final ` with no type after it)
  before committing; replace each with the explicit type.*

- **#33 [Dart] A `String` is text, and nothing else.** Never use a `String` as
  an identifier, key, enum, discriminator, table/column name, operation label,
  topic, or any other *meaning-bearing* token. Those get an `int`, a constant, an
  `enum`, or a purpose-built class — a `String` carries no compile-time check, no
  autocomplete and no rename safety, so a typo becomes a runtime bug and a rename
  becomes a silent drift.
  Common tells: a parameter named `op`/`kind`/`type`/`key` typed `String`; a
  `Map<String, ...>` keyed by anything other than genuine free text; a pair of
  `String` and `List<...>` arguments that must agree with one another (pass one
  value that owns both -- e.g. `TableDef`, not `(String table, List<FieldDef>
  field)`); a hand-written method name passed in for an error message, which is
  one rename away from lying.
  Exceptions are real but rare: human-facing prose, SQL text a dialect generates,
  and values arriving from outside the process -- parse those into a proper type
  at the boundary rather than carrying the `String` inwards.
  *Agent note: grep your diff for `String ` parameters and ask of each one
  "would a human ever read this as a sentence?" If not, it wants a type.*

### Structure / Data / Models

- **#11 [Archon] FieldDef-driven serialisation.** `toJson`/`fromJson` must loop
  the `FieldDef` list, not map properties by hand. Target ~5 lines, not 40.
- **#12 [Archon] `copyWith` via FieldDef.** Use the same FieldDef mechanism as
  serialisation where possible.
- **#13 [Archon] Client field defs build on shared field defs.** Never duplicate
  them — one source of truth.
- **#14 [Archon] Reference fields by integer column-id constant.** Access model
  fields by their stable integer column-id constant (e.g. `kTitle`), never by
  positional list index and never by string column name.
- **#15 [Global] Mock/sample data in separate files.** Never inline in
  viewmodels. Viewmodels carry no hardcoded data.
- **#16 [Archon] `SqlTypeMap` is abstractable.** Base class with DB-specific
  descendants (PostgreSQL now, SQLite for offline, others later).
- **#17 [Global] Column ordering: PK → FKs → data columns** (in tables and in
  FieldDef).
- **#19 [Global] Prefer NULL over DB defaults.** If a column would need a
  `sqlDefault` to avoid `NOT NULL`, make it nullable instead. Defaults hide bugs
  and bloat the schema.
- **#20 [Archon] Enum identity is the integer triple.** `(moduleid, typeid,
  valueid)`. The `code` column is deprecated. Never query by code or add
  code-style identifiers. Resolve enums by the triple via the `enumvalue` rows.
- **#28 [Global] No JSON on the wire — typed objects over CBOR.** Anything
  crossing a process boundary is a **proper class/Model** serialised by the
  FieldDef-driven codec seam to **int-keyed CBOR** (§6). Never a JSON body, never
  a string-keyed map, never `jsonEncode`/`jsonDecode` at an endpoint, and never a
  reply read by poking `body['someKey']` or substring-matching the payload — that
  is untyped access (#7) wearing a transport disguise. This applies to test and
  smoke clients too: they dial the same typed ops the real client dials.
  `FieldType.jsonb` remains legal as a *storage* type (a jsonb column's value is
  JSON text in the DB), as does JSON for human-facing config/log output — the ban
  is on JSON as the **wire contract** between components.
  *An existing string-keyed endpoint is not grandfathered: convert it, and if the
  shape belongs to a shared package, add the int-keyed Model there rather than
  forking a local one.*
  *JSON is **vetoed unless genuinely unavoidable** — meaning an external service
  the estate does not own. Another Gaia application is NOT that: comms between
  two Gaia applications is CBOR, so a Gaia-to-Gaia edge still speaking JSON is a
  defect to close, never an accepted exception, however long it has been there
  and however tidy its adapter looks.*
  *Where inbound JSON genuinely is unavoidable, decode it to a class **at the
  boundary**, inside the adapter that owns the foreign protocol, and let the map
  die there. The decoded `Map` has the shortest possible lifetime — measured in
  statements, not call frames. It must not be returned to a caller, stored in a
  field, or handed to a second function, because every hop is somewhere a
  string-keyed read can silently miss. A `jsonb` column is **storage, not a
  carrier**: its accessor returns the Model, not the map.*
- **#31 [Global] Every behaviour ships with a test, and coverage means behaviour,
  not lines.** Nothing lands without a test that would **fail if the behaviour
  were wrong or absent**. A test that only proves the code runs is not coverage;
  it is a second copy of the implementation.

  What must be covered, specifically:
  - **Every type that crosses a process boundary round-trips.** Encode it, decode
    it, and assert the values came back — including nulls staying null and child
    lists surviving. A wrong `FieldDef.id`, an unregistered child descriptor or a
    `FieldType` with no codec all compile perfectly and fail only when a real peer
    decodes a real reply.
  - **Every default that decides something.** If omitting a field means "preview"
    rather than "apply", or "user" rather than an explicit role, assert it — and
    assert the non-default survives the wire, because a dropped `false` inverts
    the meaning.
  - **Every invariant an identity scheme claims.** Uniqueness of ids, codes and
    topics; non-overlapping ranges; append-only-ness. These are the assumptions
    the whole estate rests on, and nothing else will notice when one breaks.
  - **Every deliberate exception**, as data with its reason attached, so the
    exception and the declaration cannot drift apart.

  **The floor is 95% line coverage, measured over EVERY line the project ships.**
  Not per-package-when-convenient and not "the packages we happen to measure":
  a runner that leaves a quarter of the codebase outside the denominator reports
  a number that is higher than the truth, which is worse than reporting nothing.
  Coverage below the floor is a finding to surface, not a level to settle at.

  Line coverage is the floor, not the goal — the clauses above are the goal. A
  file can be 100% covered by tests that assert nothing, and that is not
  coverage; it is a second copy of the implementation.


  Pure logic is unit-tested without a database or a socket; a handler's *policy*
  (what it decides) is separated from its *plumbing* (how it reads and writes) so
  the policy stays testable. When a change deletes behaviour, its test is deleted
  in the same commit — a test kept for a behaviour that no longer exists is worse
  than no test, because it reads as a guarantee.
  *Agent note: before committing, ask what would still pass if you reverted the
  change. If the answer is "everything", you have not written a test yet. Never
  claim a suite is green without running it, and never claim coverage of a file
  you did not open.*
- **#32 [Global] Prefix a package name ONLY to break a real collision.** When a
  Zen/Orac/Helix package would take a name Gaia already publishes, prefix the
  package with the application (`task` → `zentask`) and **keep the noun** — do not
  invent a new word for it, because a new word describes the thing worse than the
  original did. The **class, table and column names stay unprefixed**: only the pub
  package namespace collides, so only it needs disambiguating (`zentask` still
  exports `class Task`, table `task`).
  *Never prefix prophylactically.* Adding an app tag to everything is waste, and it
  is actively harmful: a class that later earns promotion INTO Gaia would have to be
  renamed on the way, and nothing in Gaia wants to be called `znxyz`. A name is
  prefixed the day it collides, not before.
- **#22 [Global] Version format `major.minor.release.build`** (e.g. `1.2.3.0`).
- **#23 [Archon] Each domain is its own module.** It lives in its own Dart
  **package**, registered via `ModuleRegistration` (in `core`) — service wiring,
  custom routes, and its typed Models (registered in `initialize`). Persistence
  (tables/migrations) is a separate layer **above** `core`; `core` is DB-agnostic.
  Split into small modules — never one monolith. `dependency` names other modules;
  load order = a global topological sort with `bootPriority` ordering the ready set.
  *Agent note: new domain code goes in its own small package as a `ModuleRegistration`,
  not bolted into `client/lib` or `server/lib`. ("package" = Dart package only.)*
  *(Propagate this wording to the canonical `rule.md` in orac/zen/mercury — follow-up.)*

### Testing

- **#24 [Global] Bugfix needs a failing regression test first.** Write the red
  test that fails *because of the bug*, then fix until green. The test stays as
  a guard.

### Git

- **#25 [Global] Commit messages explain why and what.** Reference the ticket
  number; write a full body, not a one-liner.
- **#26 [Global] Push after each working commit.** Push to `origin` after each
  working commit; do not batch many commits.

---

## 2. Dart language rules (quick reference)

The rules that bind **any Dart work** (`projecttypeid=1`), pulled together:

- **No `dynamic`. Ever.** Define a proper type. (#7)
- **No `Object?` when a specific type is known.** Use the actual type; define a
  value-type wrapper if needed. (#7)
- **No untyped `Map<String, Object?>`** except as a `toJson` output at a true
  boundary. Decode DB rows into real models via `Model.parseRow`; never keep
  hand-written row→map mappers. (#7, see #DB-returns-real-classes in §4)
- **No `var`** — declare the explicit type on every variable. (#27)
- **Specific class/widget names** — domain-prefixed. (#8)
- **`kind` not `type`** for reserved-word clashes. (#9)
- **Flat-lowercase filenames**, no underscores in the body. (#21)
- **Access fields by `kFoo` integer constants**, not index or string name. (#14)
- **`toJson`/`fromJson`/`copyWith` driven off the FieldDef list.** (#11, #12)

Consult the live rule list before writing Dart:
`dart run tool/bin/archon.dart rule ls`.

---

## 3. SQL / persistence rules

- **`SqlTypeMap` is a base class with DB-specific descendants** (PostgreSQL now,
  SQLite for offline, potential SQL Server/Oracle later). (#16)
- **Column ordering: PK first, then FKs, then data columns.** (#17)
- **Lowercase, singular, no-underscore table and column names.** (#18)
- **Prefer nullable columns over DB defaults.** (#19)
- **Generate SQL from FieldDef** — SQL belongs in a core/foundation
  `QueryBuilder` driven by `FieldDef` + FK links, never hand-written SQL strings
  in routes or packages. Column references go through FieldDef column-id
  constants, not repeated string literals. (see §4)

---

## 4. Architecture & layering conventions (enforced, not yet DB rows)

These emerged from recent tickets and the design plans (`plan/`). They are
mandatory in the Archon repo even though they are not yet rows in the rule table.

- **Package layering: `core` → `application` → `archon`.** `core` /
  `foundation` is platform-agnostic and reusable — it must stay usable by a
  console client, so no colour theme / presentation lives there (that goes in a
  `clapplication`-style package with platform targets: console / web / …). The
  name "Archon" lives **only** in the top `archon` package. (#393/#394)
- **No "Archon" in reusable identifiers.** Never name classes `ArchonX`; a
  different project (e.g. a "bob" project) should be able to reuse the base
  without renaming. (#393/#394)
- **Package tiers per domain: shared base + `sv`/`cl` descendants (extends #23).**
  A domain is not one package but **three, in an inheritance hierarchy**: a
  **shared base named for the domain** (`execute`, `fs`, `mesh`, `pubsub`,
  `kernel`, …) owning the request/result Models plus a base abstraction, and
  **`sv<domain>` / `cl<domain>` descendants** that *extend* the base with the
  side-specific code. `sv*` = server (`RouteDef` + handler, persistence, module
  registration, bus publish); `cl*` = client (the `ClientOp` forwarder, CLI/MCP
  surface). The `sv`/`cl` prefix **encodes the side** — there are **no `app`
  prefixes**. `sv*` and `cl*` each depend only on the base, **never on each
  other**: server code never ships in the client and vice-versa. Shared
  Models/abstractions live in the base so both descendants reuse them (no dup).
  Combined per-domain packages that carry both sides migrate to this split over
  time. (Mercury 3 crucible — `mercury*` → `kernel`/`execute`/`fs`/`http`/`json`/
  `zip`/`sys`/`mesh`/`pubsub` bases + `sv*`/`cl*` descendants — is the first
  worked example.)
- **All DB access through a single CRUD service.** One `FieldDef`/`QueryBuilder`
  -backed data-access service is the single DB gateway. Route handlers (generic
  and custom) call it — they **never** call `db.execute` or write SQL directly.
  The `QueryBuilder` lives inside that service, the layer beneath the route
  framework. (#396)
- **DB returns real classes.** Decode rows with `Model.parseRow` into typed
  models; serialise via `toJson`. Hand-written row→map mappers are a violation.
  The only legitimate `Map<String, Object?>` is a `toJson`'s output. (#376)
- **Packages self-register their routes** into core, in one place. Route paths
  compose from a core `/api` constant + the `tableName` segment — `/api` and
  table names are single constants, not repeated literals. (route registration)
- **Zero repeated string literals.** Route paths, table names, SQL column names,
  and JSON keys each have exactly one constant definition. (route registration)
- **Typed route dispatch.** Routes are dispatched through typed view classes
  (e.g. `TicketListItem`, `TicketTimelineEvent`) — no ad-hoc map building in the
  handler. (#389)
- **Enums and routes are separate concerns.** Enum identity is the integer
  triple; routes are package-owned URLs. Clients load enums via `/api/enumvalue`
  and index by triple. Never conflate the two.
- **Rules have scope.** Global vs project-type vs project — see the scope table
  at the top. Don't apply a Dart rule to a non-Dart project.
- **Wire ids are permanent — append-only, never reused (schema-evolution contract).**
  `FieldDef.id`, `OpToken.opid`, and `ModuleToken.moduleid` are stable integer
  identities minted once and **never renumbered or recycled for a different
  meaning**. A new field/op/module takes the next free id; a removed one **retires**
  its id (tombstoned, never reused). This is what makes the int-keyed wire tolerant
  across versions (protobuf-style): an old peer omits ids it doesn't know and ignores
  ids it doesn't recognise, so old↔new interop degrades gracefully rather than
  corrupting. Reusing an id silently poisons every peer that still knows the old
  meaning. The connection compat-handshake (see the comms design) builds on this.

---

## 5. Workflow rules (operating in the Archon repo)

Operational rules for an agent driving Archon's ticket workflow:

- **Honour the `claude-status` run/stop flag (Rule 0).** Check
  `archon status` before picking up any new work. Flag **on** = work the
  approved queue continuously to completion; never list tickets and ask the user
  which to do. Flag **off** = stop.
- **Surface decisions in tickets, not chat.** When the flag is on, never halt to
  ask in chat — comment + block the ticket and keep working, or just decide and
  build.
- **Use the `archon` CLI, never curl/python the live API.** If a verb is
  missing, extend the CLI (`tool/bin/archon.dart`). (Read-only fetches in this
  doc are illustrative only.)
- **Ticket lifecycle:** transition to `inprogress` before starting → add
  analysis comments with confidence + time estimate → transition to
  `claudereview` when done → push after the commit. Check children are done
  before transitioning a parent.
- **Check ticket freshness first.** Verify the symptom still reproduces in
  current code before moving a bug to `inprogress`; surface stale tickets as a
  no-op review rather than fabricating work.
- **Build the web client from the right directory.** `flutter build web` must be
  run from `client/` — the workspace root has no `main.dart` and the build
  silently exits 0 without producing output.
- **Fix rule violations holistically.** A file breaking several rules is fixed
  in one pass; don't declare "done" until a grep for the violation is clean.

---

*This document is self-contained as of its snapshot date, 2026-06-08. It is a
complete transcription of the rules in effect — no DB or network access is
required to apply them. The live DB rule table remains the source of truth over
time; if you have the Archon repo, re-run `dart run tool/bin/archon.dart rule ls
--json` to check for changes since this snapshot.*
