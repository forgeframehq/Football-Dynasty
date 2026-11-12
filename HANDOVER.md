# Football Dynasty — Handover (12 Nov 2026)

## Where things stand
- v0.6.0, commit `a320804` on `main`, APK published on release tag `latest` (87.4 MB).
- Personal football manager for Android (not for publishing): FIFA/PES career feel with Football Manager Mobile depth.
- Godot 4.7.2, GDScript, GL Compatibility, all UI built in code. Landscape, base viewport 1100×620, immersive and edge-to-edge.
- Repo `forgeframehq/Football-Dynasty` (public). Real player, club and league names (17,849 players, 49 leagues).
- `ROADMAP.md` is the ticked feature list and the source of truth.

Standing rules:
- No real crests, player photos or league logos. No player photos at all. Trophies must be original designs.
- Pushing to `main` builds and publishes the APK. If told "don't make the apk yet", commit locally only.
- Screens must be dense and practical: little blank space, information visible without tapping, action buttons always reachable.
- Nothing has been tested by Claude on a real phone; only desktop screenshots and headless season simulations.

## Build, test and ship
- Parse errors: `godot --headless --path . --import`, search output for "error".
- Simulate: `godot --headless --path . -- --selftest N [club=ID]`.
- Screenshots: run under xvfb at 1380×620 with `-- --shots only=key1,key2` (script `dev/shots.gd`). Keys: menu, new, intro, home, inbox, squad, tactics, training, fixtures, finances, board, jobs, table, comps, stats, transfers, scouting, club, menus, lists, hub, social, player, deal, life, tactics2, city, trophies, match.
- Helper scripts lived in `/tmp` and are gone: recreate an xvfb wrapper and a Pillow script that tiles PNGs into a sheet.
- Build check: `gh run list -R forgeframehq/Football-Dynasty --limit 1`; APK: `gh api repos/forgeframehq/Football-Dynasty/releases/tags/latest -q '.assets[]'`.
- Commits: author `Claude <noreply@anthropic.com>`; end messages with the Co-Authored-By and Claude-Session lines the session supplies.
- Bump `config/version` in `project.godot` and `version/code` + `version/name` in `export_presets.cfg` together (now 0.6.0, code 6).

## Code map
- Autoloads: `DB` (data), `UI` (`scripts/ui.gd`), `G` (`scripts/game.gd`). Save is `G.s`, binary, integer keys survive.
- Libraries on `G`: `ME` match engine, `LG` leagues.gd, `CP` comps.gd, `TR` transfers.gd, `DL` deals.gd (transfer talks, instalments, add-ons, sell-on, role promises, rival bids, sale counters), `PS` persona.gd (personality, favoured club, languages, caps, career, season history), `OPS` club_ops.gd (facilities, scouting, club money, manager's money), `SOC` social.gd, `RL` roles.
- Shell `scripts/main.gd`: icon rail (inbox, home, club, manager, world, search, options), slide-out menus, top bar with Continue, `SCREENS` map, `root()/open()/back()`.
- Screens in `scripts/screens/` extend `screen.gd`. Preferred layout: `panes(sep, pad)` + `pane(width, sep)` → `[panel, vbox]`. Older layout: `content()` flow pages in three columns.
- Widgets: `UI.trow(cells, widths, opt)` compact table row, `UI.kv`, `UI.stat_tile`, `UI.seg`, `UI.slider`, `UI.btn`, `UI.flag`, `UI.badge`, `UI.ovr`, `UI.pos`. Messages: `G.msg(title, text, kind, ref, important)`.
- New or rebuilt screens: `deal.gd` (registered as `nego`; modes buy, free, renew, sell), `life.gd`, `search.gd`, `player.gd` (six pages), `table.gd`, `stats.gd`, `comps.gd`, `scouting.gd`, `transfers.gd`, `jobs.gd`. `hub.gd` and `lists.gd` hold many small pages chosen by `args.kind`.

## What is left (suggested order)
1. Finish the dense pass: training, finances, fixtures, club view, board, home, and the `hub.gd` / `lists.gd` pages.
2. Get phone feedback on v0.6.0: table text size (18–19), full screen, cut-out spacing.
3. World system: continent > nation > competition > club picker; up to five playable nations (club's nation locked); background real nations with estimated results; placeholder nations generated on first open; generated players scoutable and buyable but with capped, uncertain potential and fair prices (no wonderkid loophole). Needs nation/continent table and an open-source flag set.
4. Transfer extras: deadline-day live event, loans through the talks screen, swaps, shortlist alerts.
5. Match depth: two-legged ties, extra time, shoot-outs, opposition instructions, tactical familiarity, partnerships.
6. People: rival managers with memory, Manager Watch, conversations, player stories, staff.
7. Lifestyle later: family, legacy items (statue, stand), property abroad.
8. Presentation: kit editor with sponsor logo, city match-day crowds and night lighting, goal/trophy/signing animations.
9. Modes: holiday mode, save backup, custom dashboard, create-a-club, quick match, tutorial, legends, international football.

## Assets awaited
- Suno music tracks from Sudhi → `assets/music/track_1.mp3` … `track_12.mp3`.
- Open-spaces city pack (park, car parks, fan plaza, construction site, farm field, trees).
- Scouting office level 1 re-export (PNG truncated).
- Optional: two replacement trophies (league title, top continental; `trophy_01` and `trophy_04` unused), bolder logos for PulseDyn, Apex Motors, TurboForge, TerraSpark, continent pictures.

## Known gaps
- Caps, pre-save career totals, personality and favoured club are generated, not real data. Season history fills from the current season on.
- Typed social posts are judged by keywords only. Old saves from before v0.6.0 were not tested.
- Dataset source: `github.com/bca2519-afk/easpprts_application` (`players.csv`).

## Pitfalls
- The ElevenLabs API key was pasted in chat; it should be regenerated and must never go in the repo.
- `godot --check-only -s file` falsely reports "Identifier not found: G". Use `--import`, shots and selftest.
- `c.build` is `null` when idle. Zero-size custom-draw controls get culled. Literal `%` in format strings is `%%`.
- AI clubs may have an empty `xi`; use `c.players`.
- `G.TR.move()` clears release clause, sell-on and role promise; set new ones after it.
- Fixtures are not sorted by day once cups are added.
- City sprites need `tools/prep_iso.py`. Check ChatGPT image packs for slivers and fake transparency.
