> ⛔ **NO INSTALLS ON THIS MACHINE WITHOUT PERMISSION!**

> 📦 **Versioning rule — a source change REQUIRES a version bump in the related package.** Any change
> to a package's source bumps that package's `version` (patch: 0.3.1 → 0.3.2 → …). Group a batch of
> related changes into ONE bump so the number doesn't balloon — but nothing ships without bumping the
> package(s) touched. Registry versions are immutable; an un-bumped republish 409s.

# Orac — Configuration, Toolchain & Reuse Manifest

> **Remote-access policy — Mercury REPLACES SSH (2026-07-17):** SSH/SCP are retired. For **every**
> remote command, file transfer, build, or deploy on **any** node (Windows *and* Linux), drive the
> **Mercury agent** over HTTP (`/run`, `/upload`, `/download`, `/zap`, `/restore`; key
> `m3rc7f3a9c2e1b8d4056`), **never `ssh`/`scp`**. The Linux host `192.168.101.193` runs a Mercury
> daemon on `:8199`; the Linux exe builds via Mercury there in a dedicated **mercury-minipod**
> container (do NOT disturb the gaia/orac pods). Windows exes build **only** on `192.168.101.161`.

### Build pods on the agent VM (192.168.101.193)

Reached via **Mercury only** (`/run`, key `m3rc7f3a9c2e1b8d4056`) — never `ssh`/`scp`.

| pod | image | for |
|---|---|---|
| `mercury-minipod` | — | Linux Dart/Flutter exe builds |
| **`rust-nano`** | `docker.io/library/rust:1-bookworm` | **Rust `cdylib` connector builds** (`rustc` 1.97.1, x86_64) |

**This Windows machine is a Dart builder, not a Rust one.** Do not install a Rust
toolchain here; the connector libraries are built in `rust-nano` and fetched back.
Windows exes build only on `192.168.101.161`.

**Gotcha:** `rust-nano` does not put cargo on the default `sh` PATH. Use the
absolute path or export it:

```bash
podman exec rust-nano sh -lc 'export PATH=/usr/local/cargo/bin:$PATH; cargo build --release'
```

Self-contained reference for the tooling, build/compile commands, container stack, and **what is reused from Archon** so Orac can be set up on a fresh machine without consulting the Archon repo. Distilled from Archon's `.claude/skills/archon/SKILL.md`, `docs/agent-vm-deploy.md`, `pubspec.yaml`, `analysis_options.yaml`, and README. Orac is **based on Archon** (same three-tier Dart stack); the design rules it must obey live in [`rule.md`](rule.md) (verbatim copy of Archon's), and the design itself in [`plan/orac-design-spec.md`](plan/orac-design-spec.md).

> **Note:** Archon has no file literally named `configuration.md`. This document is the Orac equivalent, assembled from the Archon sources above.

---

## 1. Stack & toolchain

| Layer | Technology | Version |
|---|---|---|
| Language (everything) | Dart | SDK `^3.7.0` |
| UI | Flutter | 3.35+ web (CanvasKit) — same as Archon's dashboard. *(Desktop deferred to later; reuses the same `cl*` packages.)* |
| Server | Dart `shelf` + `shelf_router`, compiled native (`dart compile exe`) | — |
| Database | PostgreSQL + **pgvector** | PostgreSQL 16 |
| AI (provider-agnostic) | Ollama (local on pod) or cloud API | — |
| Containers | Podman + `podman-compose`, rootless | Podman 4.9.3 |
| Hosting | agent-vm (dev), Proxmox (prod later) | — |

Everything is Dart — client, server, and shared model packages. Shared packages eliminate client/server duplication.

## 2. Lint / analysis configuration

`analysis_options.yaml` (copied into the Orac root) is **part of the rule enforcement**, not decoration — it mechanically catches the rules in `rule.md`:

```yaml
include: package:lints/recommended.yaml
analyzer:
  language:
    strict-casts: true          # blocks implicit downcasts (supports "no dynamic")
    strict-raw-types: true
  errors:
    unused_import: error
    unused_local_variable: warning
linter:
  rules:
    - always_declare_return_types
    - annotate_overrides
    - avoid_dynamic_calls          # supports rule #7 (no dynamic)
    - prefer_final_locals
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_single_quotes
    - sort_constructors_first
    - unawaited_futures            # supports fire-and-forget discipline
```

`dart analyze` must be clean before any commit. Grep your own diff for `Object?` / `dynamic` / `Map<String,` and kill every hit (rule #7).

## 3. Workspace layout (`pubspec.yaml`)

Dart workspace (`name: workspace`, `publish_to: none`), one entry per package. Orac's layout, mirroring Archon's structure (see spec §4.2):

```yaml
name: workspace
publish_to: none
version: 0.1.0+0            # major.minor.release.build (rule #22)
environment:
  sdk: ^3.7.0
workspace:
  # --- reused from Archon, unchanged (no project name in identifiers) ---
  - package/shared/foundation     # FieldDef, Value, FieldType, FkLink, entity tokens
  - package/shared/core           # Model, EntityDescriptor, SqlTypeMap, QueryBuilder, registry, events
  - package/shared/registry
  - package/shared/route
  - package/shared/schema
  - package/shared/lookup          # enumvalue
  # --- Orac domain packages (new) ---
  - package/shared/scope
  - package/shared/memory          # memory + memoryartifact + memorystep
  - package/shared/capture         # capturelog
  - package/shared/decision        # decisionlog
  - package/shared/provider        # EmbeddingProvider / LlmProvider + typed options
  # --- server (reuse/adapt from Archon) ---
  - package/server/svpostgres      # connection + migration runner (reuse)
  - package/server/svsqlite        # offline SqlTypeMap descendant (reuse, later)
  - package/server/svwrite         # serialised write service (reuse)
  - package/server/svaudit         # audit trail (reuse)
  - package/server/sverrorlog      # error logging (reuse)
  - package/server/svprovider      # Ollama + cloud impls (new)
  - package/server/svcapture       # capture queue worker (new)
  - package/server/svjanitor       # scheduled sweep (new)
  # --- client (Flutter web) ---
  - package/client/clcore          # theme, base widgets, viewmodels (reuse)
  - package/client/clapi           # HTTP client + WebSocket (reuse)
  - package/client/clenum          # EnumCache (reuse)
  - package/client/clweb           # web shell / routing (reuse)
  - package/client/cltheme         # theme (reuse)
  - package/client/clmemory        # memory screens (new)
  - package/client/clreview        # review queue (new)
  - package/client/cltimeline      # capture timeline (new)
  # --- entry points ---
  - client                         # Flutter web entry point → builds to static bundle
  - server                         # → compiles to orac-api exe (name lives ONLY here)
  - tool                           # CLI: migrate, seed, import
```

**Versioning (rule #22):** `major.minor.release.build`. Bump the workspace AND the touched package's `pubspec.yaml` on every code-touching commit. `major`=breaking (API/schema/wire), `minor`=feature, `release`=fix/refactor, `build`=rebuild only.

## 4. Compile & build commands

### Server (Dart native binary)
```bash
cd /d/orac
dart compile exe server/bin/main.dart -o build/orac-api
```

### CLI tool (compile once, run the .exe — JIT startup is ~5–10s, AOT ~0.4s)
```bash
dart compile exe tool/bin/orac.dart -o tool/bin/orac.exe
tool/bin/orac.exe <command>          # migrate | seed | import
```
The `.exe` is gitignored; recompile after editing the CLI source. **Extend the CLI rather than falling back to python/curl** (Archon gotcha G-006).

### Client (Flutter web)
```bash
cd /d/orac/client
flutter build web --release          # ~1–2 min cached, ~5 min cold → client/build/web/
```
Add `--no-tree-shake-icons` if you changed icon usage and want every glyph to ship (Archon gotcha G-027). *(Desktop is deferred; a later `flutter build windows/macos/linux` reuses the same `cl*` packages — only the entry point/target changes.)*

### Tests (TDD — run before every commit, rule #24)
```bash
cd /d/orac && dart test                       # server + shared packages
cd /d/orac/client && flutter test             # client
dart analyze                                  # must be clean
```

## 5. Container stack

Three Podman containers behind nginx (mirrors Archon's `archon-db`/`archon-api`/`archon-web`):

| Container | Role | Internal port | External |
|---|---|---|---|
| `orac-db` | PostgreSQL 16 + pgvector, persistent volume | 5432 | not exposed |
| `orac-api` | Dart shelf REST/MCP server (native exe) | 8090 | not exposed |
| `orac-web` | nginx + Flutter web bundle, proxies `/api` + `/ws` → orac-api | 8080 | 8080 |

`container/` holds the Dockerfiles + `podman-compose.yaml`. The DB volume holds the **single source of truth** — never `podman volume prune` it (Archon gotcha G-031).

```bash
cd /d/orac/container && podman-compose up -d
```

## 6. Deploy flow (adapted from Archon — every step required)

### Client web bundle (most common — pure UI changes)
```bash
cd /d/orac/client && flutter build web --release
rm -rf /d/orac/container/orac-web/html
cp -r /d/orac/client/build/web /d/orac/container/orac-web/html
md5sum /d/orac/container/orac-web/html/main.dart.js          # remember this
cd /d/orac/container/orac-web
tar -cf - html/ | ssh agent-vm 'cd ~/orac/container/orac-web && rm -rf html && tar -xf -'
ssh agent-vm 'cd ~/orac/container && podman-compose build orac-web 2>&1 | tail -1
              podman stop orac-web >/dev/null 2>&1
              podman rm -f orac-web >/dev/null 2>&1
              cd ~/orac/container && podman-compose up -d orac-web 2>&1 | tail -1'
sleep 2
curl -s http://<agent-vm>:8080/main.dart.js | md5sum         # MUST match local
```
nginx must send `no-store` on the entry points (`index.html`, `main.dart.js`, `flutter_bootstrap.js`, `flutter_service_worker.js`, `version.json`) and `no-cache, must-revalidate` on `/assets/` + `/canvaskit/` so redeploys land on the next reload (Archon gotchas G-022, G-027). If the live md5 matches but your browser shows stale UI, hard-refresh (`Ctrl+Shift+R`) to bust the service worker.

### Server image rebuild
```bash
cd /d/orac
tar --exclude='.dart_tool' --exclude='build' -cf - server/ package/ \
  | ssh agent-vm 'cd ~/orac && rm -rf server package && tar -xf -'
ssh agent-vm '
  cd ~/orac/container && podman-compose build --no-cache orac-api 2>&1 | tail -2
  podman stop orac-web orac-api 2>&1 | tail -3        # stop web BEFORE api (dependency)
  podman rm -f orac-web orac-api 2>&1
  cd ~/orac/container && podman-compose up -d 2>&1 | tail -3
  sleep 3
  podman inspect orac-api --format "Created={{.Created}}"   # MUST be NOW
'
```

**Hard-won deploy rules (Archon gotchas G-013/14/16, G-031):**
- `--no-cache` is **mandatory** on server rebuilds — podman reuses stale layers otherwise and silently ships old code.
- `podman-compose build` does NOT recreate the container; you must `stop` + `rm -f` first. `up -d` alone keeps the old container on the old image.
- Stop `orac-web` **before** `orac-api` — podman refuses to remove a container with active dependents.
- After deploy, verify `Created` is *now*, not yesterday; a non-zero build exit means the new image didn't build — don't trust a fresh timestamp alone.
- Prune proactively in long sessions: `podman image prune -af && podman builder prune -af`. **Never** `prune --volumes` (wipes the DB).
- Push a lean tar context (exclude `.dart_tool`, `build`).

## 7. Reuse manifest — what comes from Archon

Orac is built **on top of Archon's base**. The key insight (Archon rule §4, #393/#394): the reusable packages carry **no "Archon" in their identifiers** by design, so they drop into Orac unchanged.

| Package | Action | Notes |
|---|---|---|
| `shared/foundation` | **Copy as-is** | `FieldDef`, `Value`/`TypedValue`/`NullValue`, `FieldType`, `FkLink`, entity tokens — usable out of the box |
| `shared/core` | **Copy, extend** | `Model`, `EntityDescriptor`, `SqlTypeMap`/`PostgreSqlTypeMap`, `QueryBuilder`, registry, event bus. **One extension:** add `FieldType.vector` (→ `VECTOR(n)`, dimension on FieldDef) and `FieldType.tsvector` (→ `TSVECTOR`) for pgvector |
| `shared/registry`, `route`, `schema`, `lookup` | **Copy as-is** | route specs, `/api` constant, `PackageRegistration`, schema metadata, `enumvalue` |
| `server/svpostgres`, `svwrite`, `svaudit`, `svauth`, `sverrorlog`, `svsqlite` | **Copy / adapt** | migration runner, write service, audit, error log; auth simplified (single user) |
| `client/clcore`, `clapi`, `clenum`, `clweb`, `cltheme` | **Copy / adapt** | base widgets/viewmodels, HTTP client + WebSocket, EnumCache, web shell, theme — **both web, so these copy near-verbatim**; only screen content changes |
| `container/orac-web` (nginx) | **Copy / adapt** | nginx config (cache headers, `/api` + `/ws` proxy) + web deploy flow reused from Archon's `archon-web` |
| `shared/ticket`, `project`, `rule`, `person`, `planning`, `savedview` | **Drop** | Archon-domain, not needed by Orac |
| `shared/scope`, `memory`, `capture`, `decision`, `provider` | **New** | Orac domain entities (spec §5) |
| `server/svprovider`, `svcapture`, `svjanitor` | **New** | provider impls, capture queue worker, janitor scheduler |
| `client/clmemory`, `clreview`, `cltimeline` | **New** | Orac UI screens |

Orac keeps Archon's **web** three-tier shape, so the reuse is broad: backend, package structure, model/serialisation layer, SQL generation, `core`/`foundation`, the `cl*` client scaffolding, and the `orac-web` nginx container + deploy flow all map across directly. What's genuinely new is the **screen content** (memory-centric: search / timeline / review queue) and the Orac domain packages. *(Desktop may come later — it reuses every `cl*` package and just swaps the Flutter target.)*

## 8. Where the rules live (self-contained set)

- [`rule.md`](rule.md) — the complete, self-contained Archon rule sheet (verbatim copy). Mandatory. Read before every task; paste into every code-writing subagent prompt.
- [`analysis_options.yaml`](analysis_options.yaml) — lint config that mechanically enforces the type rules.
- [`plan/orac-design-spec.md`](plan/orac-design-spec.md) §16 — itemised conformance of Orac's design to each rule.

---

## Mercury mesh & herschel NAS (lab infrastructure reference)

Added 2026-07-02. Self-contained so any machine reading this configuration knows how to reach the shared store and the mesh.

### herschel — the NAS (SMB/CIFS, **NO SSH**)
- Host `herschel` → `192.168.82.5`; FQDN `herschel.cloud.lablogic.com` (also `herschel.lan.shf.lablogic.com`).
- **Do not `ssh` it** — it's a NAS. Access over SMB: `\\herschel.cloud.lablogic.com\user\rbeeston\...` (bash: `//herschel.cloud.lablogic.com/user/rbeeston/...`).
- **Transport/staging only — never the home of documentation.** Use it to move bytes between machines (binaries, bundles, hand-offs): `\\herschel.cloud.lablogic.com\user\rbeeston\work\claude\`. Documentation lives **in the repo that owns it, locally** — a doc that only exists on the NAS is unreachable the moment the share is not mounted (Mercury's own usage doc is `mercury/README.md`).

### Mercury — single-binary mesh agent/CLI (use instead of curl/ssh)
Runs commands, moves files, fetches HTTP, greps, etc. on any mesh node. A Claude talks only to its **local** daemon. Source: forgejo `jrb/mercury` (`http://192.168.101.137:3000/jrb/mercury`).

**CLI routing & gotchas (verified 2026-07-11):** `exec` and `fs.*` ops have **no working `--target`/`--peer`/`--node`/`--host` flag** — any such flag is silently ignored and the op runs **locally**. Route to a peer with the **`MERCURY_TARGET`** env var (with `MERCURY_KEY`); the binary's string table also exposes `MERCURY_PEERS`/`MERCURY_SESSION`/`MERCURY_PORT`/`MERCURY_HOST`. (`peer.add`/`sys.info` may still accept `--target`, but `exec`/`fs.*` do NOT.) Other gotchas: **`cmd.exe` is broken as an `exec` target** — env-routed `exec -- cmd /c "…"` comes back empty/local (its args are dropped); use `powershell -NoProfile -Command "…"`, or write a `.bat` via `fs.write` and run it by file association. **`fs.write` reads its content from stdin**, not `--content`/`--in-file` (those write the literal string, not the bytes): `cat local | mercury fs.write --path '<remote>'`. **Don't detach a long job with `Start-Process -RedirectStandardOutput/-Error`** — that hangs the `exec` relay; have the detached script self-redirect its own output to a log (`> log 2>&1`) and poll it with `fs.read`. See Pharos `configuration.md` for the fully verified recipe + timing.

**Binaries** on herschel at `...\work\claude\mercury\`:
| file | build | mesh? | sha256 |
|---|---|---|---|
| `mercury-linux-x64` | Dart v0.7.0.0, Linux x64 ELF | yes | `7acf914dc205db92071fbaa25e59d375982ce8e8b6d4b4e5928db95c698901d3` |
| `mercury-windows-x64.exe` | Dart v0.7.0.0, Windows x64 | yes | `f32c8d5ffe8b95dec1a36efa1a6892b9f293d40063085566c78694524d10db7e` |
| `mercury.exe` (bare) | **LEGACY Rust v0.1** | **no** | (flat JSON API only) |
The Dart build is ALWAYS the `*-x64` binary; bare `mercury.exe` = legacy Rust (no mesh). Don't confuse them.

**Shared LAN key (LAN-only secret):** `m3rc7f3a9c2e1b8d4056`. CLI env: `MERCURY_HOST`/`MERCURY_PORT`/`MERCURY_KEY`/`MERCURY_SESSION` (defaults `127.0.0.1`/`8199`/built-in key/`cli`).

**Deploy a new Linux mesh node:**
1. Copy `mercury-linux-x64` onto it; `chmod +x`.
2. `./mercury-linux-x64 serve --key m3rc7f3a9c2e1b8d4056 --port 8199 --bind 0.0.0.0` (identity = ephemeral in-memory Ed25519, **no key file on disk**; start bare, no peers file).
3. `sudo ufw allow 8199/tcp`.
4. From the hub daemon: `mercury peer.add --name <node> --addr <ip>:8199`.
5. Drive it — **route with env vars, not `--target`** (see the CLI routing note above): `$env:MERCURY_TARGET = '<node>'` then `mercury exec -- <prog> [args]`, `fs.read`/`fs.write`/`search`, `http.fetch`, `sys.info`. Ops over `/v2`; pub/sub over WebSocket `/ws`.

**Gotchas:**
- Run the CLI from **PowerShell, not Git-bash** (MSYS mangles Windows `/flags`), or set `MSYS2_ARG_CONV_EXCL='*'`.
- Linux daemon process name is `dart:mercury` → use `pkill -f '[m]ercury serve'` (`pkill -x mercury` misses it).
- No cross-compile (`dart compile exe` = host OS only): Linux built in the forgejo `dart` container on Mac Pro podman host `claude@192.168.101.193` with `bash -c` (NOT `bash -lc`); Windows built on Dart VM `192.168.101.161`.

**Known mesh (2026-06-22):** `dev`/XE10-Base `192.168.101.174:8199` (hub) · `17f` `192.168.101.111:8200` · `macpro193`/claude `192.168.101.193:8199` (build host) · `macpro215` `192.168.101.215:8199` (PENDING) · `runner101` `192.168.101.101:8199` (PENDING). Legacy Rust node `JRB-Contracts` `10.192.41.58:8199`.

**Deployed mercury nodes (added 2026-07-02):**
- `192.168.101.119` (user `deploy`, host `deployment`) — **NEW Ubuntu VM**; mercury :8199 via systemd `mercury.service`; LVM grown to ~97 GB. SSH key `~/.ssh/vm119`; sudo drop-in `/etc/sudoers.d/deploy`.
- `192.168.101.193` (user `claude`, agent-vm) — mercury :8199 via systemd.
- `192.168.101.217` (user `claude`, host `claude`) — mercury :8199 via systemd; LVM grown to ~57 GB. SSH key `~/.ssh/vm217`.
- `192.168.101.101` (user `claude`, host `claudejobrunner`, runner101/forgejo job runner) — mercury :8199 via systemd; LVM grown to ~77 GB. SSH key `~/.ssh/yt-vm`.

## Orac deployment topology (LIVE vs DEV) — added 2026-07-02

Orac now runs on two boxes:

- **`.119` (`vm119`, user `deploy`) = LIVE / production.** Full rootless-podman stack on `orac-net`: `orac-db` (pg16+pgvector, data `/home/deploy/orac-data/db`) · `orac-api` (host :8095→8090; env `ORAC_SECRET` + `DB_*`) · `orac-web` (**:8088**→8080) · `ollama` (embedder `nomic-embed-text`) · `litellm` (:4000, `/home/deploy/litellm/config.yaml`). URL **http://192.168.101.119:8088/**. providerconfig **active** (Ollama nomic embedder + minimax-m2.7 LLM). Orac's LLM row is **MiniMax cloud-direct** (`api.minimax.io`), NOT via litellm — litellm is present but unused by orac until a providerconfig row repoints to it. **`ORAC_SECRET` must equal .193's** or the encrypted MiniMax key won't decrypt. `loginctl enable-linger deploy` is REQUIRED (rootless containers die on ssh logout otherwise). No ufw (LAN-open).
- **`.193` (`agent-vm`, user `claude`) = DEV / TEST.** Same containers, but providerconfig rows are `active=false` → orac uses **stub** LLM/embedding providers (no live calls, no MiniMax spend). Re-enable with `update providerconfig set active=true` + restart orac-api. Also hosts ariadne (:8193).

**Provider selection:** `ProviderLoader` uses the newest **active** providerconfig row per role (keys decrypted via `ORAC_SECRET`); no active row / stub kind / undecryptable key → stub fallback. So deactivating rows = stub mode.

**Deploy gotchas (hit 2026-07-02):** (1) rootless **linger** required on a fresh box. (2) `podman save A B C | podman load` COLLAPSES all tags onto one image — **ship images one at a time**. (3) orac-web bakes the bundle in at build (`COPY html/`), so building from a stale `~/orac` checkout silently serves the old UI — verify by served `main.dart.js` byte size and hard-refresh (service worker).

### Deploy to LIVE `.119` — build on agent-vm, copy images over (canonical recipe)

`.119` has **NO source checkout** — it runs images **built on `.193` (agent-vm) and copied over**. Do NOT try to `git pull`/build on `.119`. There is also **no compose file on `.119`** — its containers are plain `podman run`. Run every step from the **dev box** (it holds both `agent-vm` and `vm119` ssh keys; `.193` cannot ssh `.119`).

```bash
# 1. Push source. If CLIENT changed, rebuild + commit the baked bundle first:
cd /d/orac/client && flutter build web --release
rm -rf /d/orac/container/orac-web/html && cp -r build/web /d/orac/container/orac-web/html
cd /d/orac && git add -A && git commit -m "…"    # commit the html/ bundle too
git push forgejo gaia-conformance

# 2. Build images on agent-vm (.193). MUST export the version-stamp build-args
#    (ORAC_GIT_SHA/BUILT_AT/VERSION) or the image bakes version 0.0.0 with no
#    gitsha/builtat — the bare `podman-compose build` does NOT stamp them (only
#    deploy.sh does, and .119 doesn't use deploy.sh). Compose maps them to the
#    APP_* build-args in orac-api/Dockerfile.
ssh agent-vm 'cd ~/orac && git fetch forgejo gaia-conformance && git reset --hard forgejo/gaia-conformance
              export ORAC_GIT_SHA=$(git rev-parse --short HEAD)
              export ORAC_BUILT_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
              export ORAC_VERSION=$(sed -n "s/^version:[[:space:]]*\([^+]*\).*/\1/p" server/pubspec.yaml | tr -d " ")
              cd container && podman image prune -af
              podman-compose build --no-cache orac-api orac-web'

# 3. Ship each image ONE AT A TIME (save A B collapses tags), piped via the dev box:
ssh agent-vm 'podman save localhost/container_orac-api:latest' | ssh vm119 'podman load'
ssh agent-vm 'podman save localhost/container_orac-web:latest' | ssh vm119 'podman load'

# 4. Schema: `serve` migrates via CREATE TABLE IF NOT EXISTS, which does NOT ALTER an
#    existing table — NEW OR RENAMED COLUMNS MUST BE APPLIED BY HAND (this bit us with
#    distillcount: the api boot-looped "column … does not exist" until added):
ssh vm119 'podman exec orac-db psql -U orac -d orac -c "ALTER TABLE <t> ADD COLUMN IF NOT EXISTS <col> <type>;"'
#    (or  … -c "ALTER TABLE <t> RENAME COLUMN <old> TO <new>;")

# 5. Recreate (plain podman run; preserve env from the running container — keeps
#    ORAC_SECRET/DB_* off the command line):
ssh vm119 '
  podman inspect orac-api --format "{{range .Config.Env}}{{println .}}{{end}}" \
    | grep -E "^(ORAC_SECRET|DB_HOST|DB_PORT|DB_NAME|DB_USER|DB_PASSWORD)=" > /tmp/oapi.env
  podman stop orac-web orac-api; podman rm -f orac-web orac-api
  podman run -d --name orac-api --network orac-net -p 8095:8090 --restart unless-stopped \
    --env-file /tmp/oapi.env localhost/container_orac-api:latest serve --port 8090 --db-host orac-db
  podman run -d --name orac-web --network orac-net -p 8088:8080 --restart unless-stopped \
    localhost/container_orac-web:latest
  rm -f /tmp/oapi.env'

# 6. Verify:
curl -s http://192.168.101.119:8088/main.dart.js | md5sum   # MUST equal local html/main.dart.js
ssh vm119 'podman logs --since 10s orac-api' | grep -iE "drain error|does not exist"   # MUST be empty
```

**Hook/MCP binary:** the local capture hook + MCP server both run **one** binary — `D:/orac/tool/bin/orac.exe` (hooks in `.claude/settings.local.json`, MCP in `~/.claude.json`). Rebuild with `dart compile exe tool/bin/orac.dart -o tool/bin/orac.exe`; a running MCP holds it locked, so rebuild needs a Claude restart to release the lock. (There used to be a second copy at `~/.orac/bin/orac.exe` for MCP — removed 2026-07-05; two copies drifted and lost messages.)

---

## Plan/spec location (agent convention — `docs/superpowers` is VETOED)

**All implementation plans and design specs go in `plan/` in this repo — NEVER `docs/superpowers/`.**
The Superpowers `brainstorming` / `writing-plans` skills default to `docs/superpowers/specs/` and
`docs/superpowers/plans/`; that path is **vetoed by the owner**. Write specs as
`plan/YYYY-MM-DD-<topic>-design.md` and plans as `plan/YYYY-MM-DD-<topic>-plan.md`.
