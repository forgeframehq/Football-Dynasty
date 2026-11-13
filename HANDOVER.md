# Football Dynasty 26 — Handover (12 Nov 2026, v0.7.0 on `dev`)

## Where things stand
- `main` and the published APK are still v0.6.2. All work since is on branch `dev` as v0.7.0 and has NOT been built into an APK: Sudhi said "don't build the APK". Merge `dev` into `main` only when he asks for one.
- v0.7.0 adds the tactics system, the transfer system, the Football Dynasty 26 branding (icon, wordmark, purple and gold scheme) and the intro film. See ROADMAP.md for the ticked list.
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
- Helpers are in the repo: `GODOT=/path/to/godot dev/shots.sh key1,key2 [days=N] [notch=PX]` prints script errors and saves PNGs; `python3 dev/sheet.py out.png` tiles them. Extra keys: `dense` (round view, club view), `exit` (confirm pop-up). `days=N` plays N Continue presses first (about 75 is a whole season); `notch=PX` fakes a camera cut-out on the left.
- Godot is not preinstalled: download `Godot_v4.7.2-stable_linux.x86_64.zip` from the godotengine/godot GitHub releases.
- Build check: `gh run list -R forgeframehq/Football-Dynasty --limit 1`; APK: `gh api repos/forgeframehq/Football-Dynasty/releases/tags/latest -q '.assets[]'`.
- Commits: author `Claude <noreply@anthropic.com>`; end messages with the Co-Authored-By and Claude-Session lines the session supplies.
- Bump `config/version` in `project.godot` and `version/code` + `version/name` in `export_presets.cfg` together (now 0.7.0, code 9).

## Code map
- Autoloads: `DB` (data), `UI` (`scripts/ui.gd`), `G` (`scripts/game.gd`). Save is `G.s`, binary, integer keys survive.
- Libraries on `G`: `TC` tac.gd (playstyles, instructions, skills, link-ups, style fit, form arrows, Team of the Week), `MK` market.gd (briefs, loans, pre-contracts, buy-backs, matching rights, agents, deadline day), `ME` match engine, `LG` leagues.gd, `CP` comps.gd, `TR` transfers.gd, `DL` deals.gd (transfer talks, instalments, add-ons, sell-on, role promises, rival bids, sale counters), `PS` persona.gd (personality, favoured club, languages, caps, career, season history), `OPS` club_ops.gd (facilities, scouting, club money, manager's money), `SOC` social.gd, `RL` roles.
- Shell `scripts/main.gd`: icon rail (inbox, home, club, manager, world, search, options), slide-out menus, top bar with Continue, `SCREENS` map, `root()/open()/back()`.
- Screens in `scripts/screens/` extend `screen.gd`. Preferred layout: `panes(sep, pad)` + `pane(width, sep)` → `[panel, vbox]`. Older layout: `content()` flow pages in three columns.
- Widgets: `UI.trow(cells, widths, opt)` compact table row, `UI.kv`, `UI.stat_tile`, `UI.seg`, `UI.slider`, `UI.btn`, `UI.flag`, `UI.badge`, `UI.ovr`, `UI.pos`. Messages: `G.msg(title, text, kind, ref, important)`.
- New or rebuilt screens: `deal.gd` (registered as `nego`; modes buy, free, renew, sell), `life.gd`, `search.gd`, `player.gd` (six pages), `table.gd`, `stats.gd`, `comps.gd`, `scouting.gd`, `transfers.gd`, `jobs.gd`. `hub.gd` and `lists.gd` hold many small pages chosen by `args.kind`.

## What is left (suggested order)
1. Finish the dense pass: only the small pages in `hub.gd` and `lists.gd` are left (training, finances, fixtures, club view, board and home were done in v0.6.1).
2. Get phone feedback on v0.6.1: table text size (18–19), the rail beside the camera cut-out, the confirm pop-ups.
2b. Tactics and transfer systems are built (v0.7.0). Specs: project docs `claude/TACTICS_PLAN.md` and `claude/TRANSFER_PLAN.md`. Still open from them: the pitch overlay does not draw the new instructions; match boosts are deliberately small and want tuning once Sudhi has played; nothing has been tried on a phone.
2c. Assets coming from Sudhi: trophy and promotion films from Kling (16:9, no faces, no real crests). Convert with `ffmpeg -c:v libtheora -q:v 8 -c:a libvorbis` to `assets/video/win_league.ogv`, `win_cup.ogv`, `win_euro.ogv`, `win_promo.ogv`; `main.play_pending_film()` plays them when `s.user.film` is set. He may also resend the intro clips at 720p (current ones are 736x400).
3. World system: continent > nation > competition > club picker; up to five playable nations (club's nation locked); background real nations with estimated results; placeholder nations generated on first open; generated players scoutable and buyable but with capped, uncertain potential and fair prices (no wonderkid loophole). Needs nation/continent table and an open-source flag set.
4. Transfer extras: deadline-day live event, loans through the talks screen, swaps, shortlist alerts.
5. Match depth: two-legged ties, extra time, shoot-outs, opposition instructions, tactical familiarity, partnerships.
6. People: rival managers with memory, Manager Watch, conversations, player stories, staff.
7. Lifestyle later: family, legacy items (statue, stand), property abroad.
8. Presentation: kit editor with sponsor logo, city match-day crowds and night lighting, goal/trophy/signing animations.
9. Modes: holiday mode, save backup, custom dashboard, create-a-club, quick match, tutorial, legends, international football.

## Assets awaited
- Music: seven Suno songs are in (see the settings section at the end). More can be added to `UI.SONGS`.
- Open-spaces city pack (park, car parks, fan plaza, construction site, farm field, trees).
- Scouting office level 1 re-export (PNG truncated).
- Optional: two replacement trophies (league title, top continental; `trophy_01` and `trophy_04` unused), bolder logos for PulseDyn, Apex Motors, TurboForge, TerraSpark, continent pictures.

## Known gaps
- Caps, pre-save career totals, personality and favoured club are generated, not real data. Season history fills from the current season on.
- Typed social posts are judged by keywords only. Old saves from before v0.6.0 were not tested.
- Dataset source: `github.com/bca2519-afk/easpprts_application` (`players.csv`).

## Pitfalls
- Player field `pre` belongs to persona.gd (pre-save career totals). The pre-contract field is `prec`. Check `grep` before adding a short key to a player.
- `link_pair` and `active_links` take slot positions (`G.TC.slot_pos(c)`), not role ids (`c.roles`). In the engine `t.roles` is positions and `t.rids` is role ids.
- Engine balance: baseline is about 2.8 goals a game and top scorers in the 40s over a season (`--selftest 1`, CALIB line). Anything that adds chances or weights strikers moves it fast; re-run after engine changes.
- `dev/mktest.gd` (`-- --mktest`) exercises every transfer feature and the tactics data headlessly. `dev/shots.sh` keys added: tacsetup, tactics2 (six tabs), deal (two-day flow), market (brief, loan sheet, deadline day); `--intro` plays the intro in a shots run.
- Config name is now "Football Dynasty 26", so the desktop user-data folder changed; the Android package id is unchanged, so phone saves carry over. Loading a v0.6.2 save was tested headlessly for two seasons.
- The accent colour comes from the chosen skin (`UI.apply_accent()`), or the club's colour if that setting is on.
- A plain `UI.lbl` with a long sentence sets a huge minimum width and pushes the whole screen off the right edge on notched phones (this was the tactics hint line). Use `UI.lbl_fill` or `UI.wrap` for anything longer than a few words, and check screens with `notch=70`.
- Tactics agreed with Sudhi so far (12 Nov, build only after he says go): manager-owned link-up plays as in eFootball (pick one at career start, more per coaching badge, two slots that fitting players activate, bronze/silver/gold with minutes together), team playstyles with manager proficiency, extra Defence/Attack options, generated player skills. Tactics page is extended, not rebuilt.
- Inside a lambda in `ui.gd`, a bare `wrap(...)` calls Godot's built-in maths `wrap()`, not the label helper. Write `self.wrap(...)`. This is what broke every `UI.confirm` pop-up up to v0.6.0.
- `G.advance()` runs to the next stop (match day, important message), not one day.
- Left cut-out: `main.gd` keeps `notch_l`; with the rail showing, the safe margin is 0 and the rail is `rail_w()` wide with its icons pushed right of the cut-out. Screens without the rail still get the full left margin.
- `G.OPS.week_money(c)` is the single source for weekly club income and costs; `weekly()` and the Finances screen both use it.
- The ElevenLabs API key was pasted in chat; it should be regenerated and must never go in the repo.
- `godot --check-only -s file` falsely reports "Identifier not found: G". Use `--import`, shots and selftest.
- `c.build` is `null` when idle. Zero-size custom-draw controls get culled. Literal `%` in format strings is `%%`.
- AI clubs may have an empty `xi`; use `c.players`. A script error inside `dev/shots.gd` makes the screenshot run hang rather than exit: kill it and read the output.
- `G.TR.move()` clears release clause, sell-on and role promise; set new ones after it.
- Fixtures are not sorted by day once cups are added.
- City sprites need `tools/prep_iso.py`. Check ChatGPT image packs for slivers and fake transparency.

## Settings, skins and soundtrack (dev, after v0.7.0)
- New `settings` screen (scripts/screens/settings.gd), opened from the title screen and from Options. Three panes: volume sliders (music, effects, match crowd), play order, intro film on/off; the soundtrack list (tap to play, tick = in rotation); skins, accent colour (skin or club), currency symbol, default match speed.
- Everything is stored in `G.settings` (user://settings.dat): `vol_music`, `vol_sfx`, `vol_crowd` (0-100), `shuffle`, `songs_off`, `intro`, `skin`, `club_accent`, `cur`, `speed`. The old Sound and Music switches are migrated to volume levels on load.
- Skins: `UI.SKINS` (Dynasty, Midnight, Pitch, Crimson, Graphite). `UI.BG, BG2, CARD, CARD2, BRAND, MUTED, DIM, RAIL` are now vars set by `UI.apply_skin()`; `UI.main.reskin()` recolours the frame and redraws the screen. Some screens still have hard-coded dark colours.
- Soundtrack: seven songs in assets/music (128 kbps MP3, 29 MB), listed in `UI.SONGS` with titles and lengths. `UI.songs()`, `music_play(i)`, `music_step(dir)`, `now_playing()`, signal `song_changed`. The title screen has a Soundtrack panel bottom right with previous / pause / next.
- Currency is a symbol change only (no conversion); `G.money()` is the single place it is applied.
