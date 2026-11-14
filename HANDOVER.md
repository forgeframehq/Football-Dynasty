# Football Dynasty 26 — Handover (14 Nov 2026, v1.0.0 on `main`)

## Start here (new chat, written 14 Nov 2026 midday)
State: `main` = `dev` = v1.0.0 (commit 2689c0a), APK published (134 MB) at https://github.com/forgeframehq/Football-Dynasty/releases/download/latest/FootballDynasty.apk. Sudhi has installed it and is giving feedback. He is collecting a new list and has said "lock it in, don't make the game yet": do not build until he says go.

How Sudhi works:
- He is on his phone: answer first, short, no preamble. He wants a direct recommendation, not options.
- He dislikes scrolling, empty space and tiny text; he wants dense, premium screens and compares everything with FM Mobile 26 and EA FC.
- He likes to agree a list, then say "build it all" and leave it overnight. When he does, finish everything, and say plainly what was not done.
- Commit and push to `dev` freely. Push to `main` (builds the APK) only when he asks for an APK or says to complete the game.
- He sends free asset packs when asked (Kenney kits, Mixamo, Meshy, Suno songs, ChatGPT/Kling art). Tell him exactly which file to download.

Built on `dev` 14 Nov afternoon (not on `main`, no APK yet): see "dev after v1.0.0" at the end. Item 1 below is partly done (small camera hole), the long-notch case is not.

New list (locked in, not built):
1. Full-screen backdrops. On screens without the side rail (title, new career, intro, pre-match, live match, full time) the background stops at the camera safe margin and leaves a bare purple band on the left. Run the background edge to edge under the cut-out; keep only the logo, buttons and panels inside the safe area. In main.gd the `safe` MarginContainer holds everything; the backdrop needs to sit outside it.
2. A FIFA-style intro film, about 25 s: tunnel walk-out, aerial stadium at night, fast cuts on the beat, slow-motion strike, logo slam, into the menu. Kling-type clips for crowd, tunnel and slow motion (16:9, no faces, no real crests); the stadium flythrough, kit shots and logo reveal rendered from the game's own 3D; a 30 s Suno track; cut with ffmpeg. Full version on first launch, a short one after, tap to skip, existing intro setting turns it off.
3. He offered a Kie (kie.ai) API key with 1,000 credits to generate the clips. api.kie.ai is reachable from the workspace. Agreed plan: with the key, first read the balance and per-model cost and report; then one cheap test clip; only then the rest. Use the key from the shell only, never in the repo, and ask him to regenerate it afterwards.

Open points from v1.0.0 to raise when relevant:
- Nothing was tried on a real phone. Ask about speed and heat with 22 animated players, the 3D home, and the rail beside his camera.
- He reported the goalkeeper bigger than the net; goals were rescaled (`GS` in match3d.gd) in the final v1.0.0 build. Confirm it looks right.
- Top scorers still run high for the very best strikers (Haaland 63 in all competitions in one simulated season).
- Not built: world system (more nations, generated players), victory films (waiting for his clips), sprint and celebration animations (Mixamo "Fast Run" and a "Victory").
- The ElevenLabs key was pasted in chat twice and used for sounds and the commentary voice; he should regenerate it.

Workspace notes (the cloud workspace may be new in a new chat):
- Clone `forgeframehq/Football-Dynasty`, download Godot 4.7.2 (see Build, test and ship).
- The Mixamo source files and the bake script (`bake.gd`: reduces the skeleton to 23 bones and builds `soccer.res`) were in a scratch project outside the repo. Only the baked `assets/m3d/rig.scn` and `assets/m3d/soccer.res` are in the repo. To add animations, ask him for the Mixamo FBX again and rewrite the bake from the v1.0.0 notes.
- Unused asset packs he sent are not in the repo: 11 more stadium models, the rest of the Kenney car kit, city kits, two usdz supercars, the Meshy shirt was never uploaded.

## Where things stand
- `main`, `dev` and the published APK are v1.0.0, built overnight 14 Nov at Sudhi's request from the list he drew up after playing v0.9.0 (see the v1.0.0 section at the end). Work on `dev`; push to `main` only when he asks for an APK.
- Awaiting from Sudhi: phone feedback on v1.0.0 (speed and heat with 22 animated players, the 3D home, the rail beside his camera), Kling victory films, and optionally a sprint and a celebration animation from Mixamo.
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
- Bump `config/version` in `project.godot` and `version/code` + `version/name` in `export_presets.cfg` together (now 1.0.0, code 13).

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
- `G.advance()` runs to the next stop (match day, important message), not one day; the game itself now uses `G.advance_day()` through `main._go()`.
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
- Currency: the save stays in euros; `G.money()` converts for display at fixed rates (`G.CUR_RATE`: £0.85, $1.15 per euro).

## v0.7.1: rail, menus, Kit & Sponsors, confirms
- Rail: icons use the strip beside a small camera hole and step over it (`main.hole`, from `DisplayServer.get_display_cutouts()`; dev args `notch=PX hole=Y0-Y1`). A long notch or an unknown cut-out keeps the old layout (`rail_wide()`). Three groups with dividers (Inbox, Home / Club, You / World, Market), Settings pinned at the bottom, a small label under each icon.
- Slide-out menus are grouped under headings in two columns with no scrolling: `MENU_GROUPS` in main.gd names the rows per group; `menu_items()` still builds the rows.
- `kit` screen (scripts/screens/kit.gd, widget scripts/widgets/shirt.gd): live shirt, six patterns (`c.kitp`), colours, and this season's sponsor offers with a preview on the shirt and a confirm before signing. Replaces the Sponsors hub page in the menus; Club Identity is now Club Records.
- `G.OPS.sponsor_now()` is the only valid way to read the sponsor (it checks the season). `G.OPS.sponsor_call()` sends the important "Sponsor offers are in" message at new game, new job and season rollover; Home's To Do shows it until one is signed. There are no sponsor targets in the code.
- `UI.confirm(..., danger, no)` takes a back-out callback; used for the permanent best-playstyle and link-up choices (tac_sheets.gd).

## v0.8.0 (dev): match engine — match-ups, stars, upsets
- `G.TC.matchup(a, b)` (tac.gd): seven rules compare both sides' instructions and unit traits (`traits()`: pace, passing, pressing, aerial) and return multipliers for att/mid/def/chance rate plus notes. `MU` scales the lot (0.68). Called in `ME.recalc()` every tick, so in-match changes count. Notes use `{A}` / `{b}` placeholders (never `%`: they pass through format strings).
- Pre-match opposition report (match.gd) shows the verdict and the top three reasons, and says when the AI has changed style to stop you.
- AI adapts: `TC.ai_plan(c, opp)`. Against the user only, after 3+ matches in the same playstyle, an AI manager may switch to `COUNTER_STYLE` (chance grows with the streak and his club's rep; he is 12 points less proficient in it). Deterministic per match (`s.user.mp`), so the report and the match agree. `lineup()` returns `pstyle`; `side_setup` honours it.
- Stars: in `recalc`, a player well above his own XI's average gets more of the shooting/assist share, a shot-quality bonus (`pm[pid].star`) and lifts team attack; tight-marking him (`tm` pin) removes most of it. A standout defender lifts defence.
- `ME._on_the_day()`: each side gets a small random swing; a favourite (rep +7 or higher division) may take the game lightly (less often with high morale); a lower-division side at home in a knockout tie gets a lift. `t.under` marks the underdog; game state in `recalc` makes a leading underdog dig in and a trailing favourite take risks.
- Role suitability now 0.90-1.03 (was 0.955-1.025); proficiency/familiarity swing -6% to +5.5%; link-up team boost doubled.
- Strength curve flattened slightly (chance exponent 1.95, possession 2.4) and `PS_K` retuned: about 2.75-2.85 goals a game.
- `dev/tactest.gd` (`-- --tactest n=400`) measures all of this: strength, each choice at equal strength, the 5x5 style grid, the underdog grid and cup ties. Results swing by about +/-0.07 points a game at n=400; do not tune on single cells.
- Measured after the change: best-to-worst style choice against a given opponent style is worth roughly 0.3-0.4 points a game at equal strength; mastered-and-settled against poor-and-unsettled 1.53 v 1.00; worst roles 1.08; underdog win chance against the top side 7-26% depending on plan (was about 14% whatever you did); best second-tier side at home to the best top-tier side goes through 26%.

## v0.9.0: 3D match, commentary, sounds, contract talks, car market, 3D city, game check
- Match view: `scripts/widgets/match3d.gd` (SubViewportContainer). A textured pitch, simple stands, 22 figures built from boxes in kit colours, a ball. Open play follows the engine's `sim.ball` with the same shape maths as the flat pitch. Each shot event is staged by `play(e)` (pass, shot, outcome, celebration); `impact` fires when the ball arrives, `seq_done` at the end. The engine's shot events now carry `k` (kind), `as` (assister), `blk`.
- Viewing mode `G.settings.view`: 0 watch, 1 key moments (default), 2 text only; chosen before kick-off or in Settings. In match.gd, events from a step with a shot are held in `deferred` until `impact`, so the score never spoils the move. At full time the flat pitch returns for the shot map.
- Textures come from `tools/make_match_tex.py` (grass source `tools/grass_src.jpg`, from a free Unity ground pack Sudhi sent) into `assets/m3d/`.
- Commentary: `scripts/commentary.gd` (`G.CM`). `ME.ev()` passes shot lines through `CM.shot()` (build-up line by kind, alternatives, a closing remark from the match state); quiet minutes use `CM.fill()`.
- Sounds: click, open, back, confirm, continue, message, error, cash, build, tick, sign were regenerated with ElevenLabs sound generation to be soft and low. The key was used from the shell only and is not in the repo; it was pasted in chat again and should be regenerated.
- Performance: `UI.apply_perf()` caps the frame rate (`fps`: auto = 60 on menus, 30 while a 3D view is up) and turns on low-processor mode (`saver`) outside 3D. `lowgfx` halves 3D resolution and drops anti-aliasing and shadows. `UI.enter3d()` is called by the 3D views.
- Errors: `scripts/errlog.gd` is a `Logger` registered in `G.load_settings`; Settings > Diagnostics shows the count and the last entries, saved to user://errors.log.
- Manager contract: `u.mc` via `G.OPS.mc()` (end season, bonus level, release clause, patience). `mc_propose`, `board_value`, `mc_daily` (board opens talks in the final season), `mc_rollover` (one-year option if confidence is 50+, otherwise the manager is out), `mgr_bonus` on trophies and promotion. The My Contract page in hub.gd is the negotiation.
- Car market: 14 cars (`life.gd CARS`, `OPS.CAR_PRICE/CAR_UP`), `OPS.car_stock()` gives seven on sale each month with the first 12% off.
- Club City 3D: `scripts/screens/city3d.gd`, models in `assets/city3d/` (Kenney roads, suburban, commercial kits, CC0; stadium `Fst_Eng_001.FBX`, which sits on a modelling pedestal sunk by a fixed ratio). The Club menu opens it unless `lowgfx` is on; "Classic view" opens the old `campus` screen.
- Game check: `GODOT=... dev/audit.sh days=120 notch=70` visits every menu page, tactics tabs, player pages, lifestyle tabs and a match, then plays on; reports errors, slow pages, pages that scroll, off-screen and tiny text, and data problems to /tmp/audit.txt. First run found and fixed a crash on Investments in a new career.
- Not done: manager's home in 3D (needs the Kenney Furniture Kit), voice commentary, extra time and shoot-outs, the tactics pitch overlay for the new instructions. The stadium in the match view is built from boxes, not the stadium model.

## v1.0.0 (14 Nov 2026): the play-session list, built overnight
Everything Sudhi asked for after playing v0.9.0. Screens and code, in the order of his list.
- Time: Continue moves ONE day (`G.advance_day()`, `main._go(mode, target)`). The arrow beside it opens `main.travel_menu()`: next match, one week, pick a date. Fast travel stops for a match, an important message and whatever is ticked in `G.settings.stops` (`G.travel_stop`, `G.travel_mark`). Long-press Continue still runs to the next match. `G.advance()` (multi-day) is kept for the dev tools only.
- Home: the To Do card is now "Today"; `home.gd todo_items()` / `todo_count()` are static and the Continue button shows the count.
- Calendar: `scripts/screens/calendar.gd` (month grid, fixtures, key dates, "Sim to this day"); opened from the date in the top bar and the Club menu. Fixtures is its second tab.
- Rail: `_build_rail()` is eight equal cells down the full height, full-width highlight, dividers, no labels; a small camera hole is ignored (a button may sit partly behind it), a long notch still pushes the icons right.
- Screen titles: `screen.gd` resets and pushes `title`/`subtitle`, so a page can no longer show the last page's header (the "NEWS" on Kit bug).
- Search: `search.gd` rewritten. Filters live in `G.ui.srch` (`blank()`); quick lists (bargains, free, listed, expiring, top50, wonderkids, similar, role, pos) are presets of the same table with a "Why" column (`_rank`). `lists.gd` redirects those kinds. Customise page: General / Positions / Attributes, templates (`_template(p)`, a role in my tactics), saved searches in `s.user.searches`.
- Player > Manage: three panes (`player.gd _manage`). Conversations `OPS.TALKS`, `OPS.talk()`, promises checked by `OPS.talks_daily()`; mentor (`p.mentor`, `OPS.mentor_mult` in `develop_all`); duties; shirt number picker. No bottom bar on that page.
- Match day (`match.gd`): `_build_pre()` is one page (fixture card with a still 3D stadium `widgets/stadium_view.gd`, strength bars, match-up verdict, Your advantage / Their threat / Key man, kick-off block, both line-ups). `G.TC.report(uid, oid)` is the shared match-up report; Tactics shows it as a strip that updates with every change (`tactics.gd _verdict`).
- Tactics during a match: `match._open_tactics()` sets `G.live = {sim, us}` and opens the normal Tactics screen with no chrome. `G.live_sync()` turns XI changes into substitutions (bench player into the XI) or position swaps and pushes shape, roles and instructions into the sim. The club's pre-match tactics are snapshotted at kick-off and restored at full time (`_snapshot`, `_restore`).
- Live screen: pitch about 72% wide, narrower feed, half-time panel over the pitch (`_show_ht`: numbers, ratings, assistant's read `_read()`, team talk). Controls: pause, speed, Tactics, Shouts, Sim.
- Sim ahead: `_sim_sheet`, `_sim_to(target, until_event)`, `_missed()` ("What you missed", with goal replays through `view3d.play`), rules in `G.settings` (`ss_goal`, `ss_behind`, `ss_red`, `ss_inj`, `auto_fr`). Full time is one page (`_show_ft`).
- Engine: extra time (`et`, `et_at`) and kick-by-kick shoot-outs (`_shootout`, `pen_log`); two-legged European knockout ties (`comps.gd _two_legs`, fixture keys `leg`, `first`; `ME.agg`; `LG.fx_winner` uses the aggregate); weather (`G.weather(f)`, `G.WX`, `ME.wx`: small effects in `recalc` and on tiring, shown pre-match, on Home, in commentary and as rain/snow in 3D); plan triggers (`ME._triggers`). Star share of shots trimmed (0.28 / 0.25).
- Tactical plans: `scripts/screens/plans.gd` (carousel of pitch cards `widgets/mini_pitch.gd`, team sheets, assignments, triggers). Data on the club: `c.plans`, `c.plan`, `c.sheets`, `c.trig`, `c.autorot`, `c.rot_at`. Helpers in tac.gd: `plans_init`, `plan_use`, `plan_net` (scout's pick), `sheet_use`, `auto_rotate`. Old `c.presets` are migrated on first open.
- Pitch overlay: `tac_overlay.gd` draws line of engagement, compactness, offside trap, marking, tackling, build-up, final third, crossing, overlaps and time-wasting.
- 3D players: Mixamo "Soccer Game Pack" baked (scratch project, not in the repo) into `assets/m3d/rig.scn` (23-bone skeleton) and `assets/m3d/soccer.res` (30 animations, hips drift stripped except dives and tackles). `widgets/player_mesh.gd` builds a ~1,300-vertex rigged footballer in kit colours and pattern; `match3d._figure`, `_act`, `_animate`. Proper goals and nets (`_net`), second crowd tier that bounces on goals, corner flags, floodlights, dugouts, weather particles. `match3d.cancel()` drops a staged move.
- Kit & Sponsors: `kit.gd` + `widgets/kit_view.gd` (a footballer in the kit you can turn; front sponsor, name, number, back and sleeve sponsors). Kits: `OPS.kit(c, which)` (home on `c.c1/c2/kitp`, others in `c.kits`), `OPS.default_pattern`, `OPS.match_kits(home, away)` picks the least-clashing kit. Extra deals: `OPS.SPX`, `spx_offers`, `spx_sign`, `spx_week` (added in `week_money`); a stadium-name deal renames the ground until it ends.
- Club City 3D: stadium model by level (`OPS.STADIA`, `OPS.stadium_model`), flags in club colours, floodlights, day / dusk / night, traffic (`traffic`, `LOOPS`), the manager's car, scaffolding and crane that rise with the build (`_site`).
- My Home: `scripts/screens/home3d.gd` (Kenney Furniture Kit in `assets/home3d`, cars in `assets/cars3d`). Dollhouse orbit, five walk-in views, tappable things (`_spot`): TV, scrapbook, fridge, bed (moves on a day), wardrobe (kit), computer (inbox), trophies, car. Grows with `lf.home` (pool at 3, pitch at 4).
- Sound: soundtrack fades (`UI._fade_to`, `_start_song`) and ducks out at kick-off (`UI.music_duck`); the newspaper sting is off; 29 spoken commentary clips in one voice (`vo_*`, ElevenLabs TTS, "Daniel"), with a Commentary voice setting.
- Text: `UI.lbl` never goes below 14 px.
- Game check: `dev/audit.gd` now also reports overlapping buttons (anything registered with `UI.tap`) and covers the new pages. Last run: 107 pages, no overlaps, no off-screen text; the only error (stadium view variable clash) is fixed. Pages that still scroll are lists (squad, fixtures, tables, wage bill, feeds).
- Not done: the world system (more nations, generated players), victory films (waiting for Sudhi's Kling clips), a sprint and a celebration animation from Mixamo (the jog is sped up and the celebration is made in code). Nothing here has been tried on a real phone: 22 animated players and the 3D home are the things to check for speed and heat.

## dev after v1.0.0 (14 Nov 2026 afternoon): full screen, trading screen, song rotation
- Rail-less screens (title, new career, intro, pre-match, live match, live Tactics, full time): `main.left_inset()` is 0 when the cut-out is a small camera hole, so the page runs to the edge of the glass; only a long notch (`rail_wide()`) still pushes everything right. `main.hole_x` holds the hole's left/right; dev arg `hole=Y0-Y1` with `notch=PX` now draws a black pretend hole (`_dev_hole`) on screenshots.
- Menu pages built with `content()` (flow.gd `_layout_paged` / `_place`): a page that fits in fewer columns gets fewer, wider columns; the last card (100 px or taller) in each column runs to the bottom of the page; a full-width note after cards goes under them on the same page instead of opening a page of its own (that was the stray second page dot on Career Timeline and others). Manual, Game Status and Editor now use the automatic columns.
- Investments is its own screen: `scripts/screens/invest.gd` (registered as `invest`; the hub `invest` page redirects). Ticker tape (`widgets/ticker.gd`, tap a code to open it), market list with 7-day sparklines (All / Mine / Up / Down), company page with chart (`widgets/stock_chart.gd`, 1W-1Y, dashed line at your average price), key numbers and an order ticket (10 / 100 / 1K / 10K / Max, 0.2% fee), right pane Shares / News / Savings / Property / Work. Prices tick live every 1.6 s while it is open (not at weekends); the screen calls `UI.enter3d(true)` so the moving tape runs at the 30 fps cap.
- Market model in club_ops.gd (end of file): `TICK` codes, `SECTOR` volatility and dividend yield, `market_day()` from `OPS.daily()` (market + sector + own move, 1.2% daily chance of company news with a headline in `lf.mnews` and a message if you hold it and it moved 7%+, shirt sponsor gets a small lift, no trading Sat/Sun), `market_tick`, `trade(lf, i, qty)`, `portfolio`, `dividends` (paid weekly, in the ledger). Life record keys: `ph` (260 daily closes per company, made up on first open), `cost` (average price), `mnews`, `trades`. The old weekly ±8% price jump is gone. Old saves migrate in `market_init`.
- Music: `UI._launch_song()` starts each launch on the song after last launch's opener (`G.settings.last_song`), or a random different one on shuffle.
- Checked: `--selftest 1` (2.79 goals a game), `dev/audit.sh days=30 notch=74 hole=292-344` (107 pages, no errors, nothing off screen, no overlaps), screenshots of every page with the pretend hole. Not tried on a phone.
