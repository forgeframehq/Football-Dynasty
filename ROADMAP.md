# Football Dynasty roadmap

Agreed feature list for the landscape rebuild (v0.3 onward). Items are ticked when they ship in an APK.

## Rules
- Landscape only. Left icon rail, top bar with a persistent Continue button, slide-out menus.
- Real player, club and league names; no real crests, photos or league logos. Clubs use generated shields, nations use drawn flags.
- Vector icons, flags, shields, kits and the pitch are drawn in code. Buildings, scenes, trophies and portraits come from generated images.
- Ship in stages, with an APK after each stage.

## Stage 1: landscape shell
- [x] Landscape layout for every screen
- [x] Icon rail: Inbox, Home, Club, Manager, World, Search, Options
- [x] Slide-out menus with live info on each row
- [x] Continue button that says why it stopped; long-press runs to the next match
- [x] Home dashboard with six panels and a To-Do list
- [x] Inbox and news as two panes with a subject card, tags and action buttons
- [x] Squad as a sortable table
- [x] Match screen with a wide pitch and side panels
- [x] Start sequence: title screen, Nation > League > Club picker with club panel and Random Team, manager profile, board meeting, breaking-news scene
- [ ] Start sequence extras: mode select, game-world detail setting, first three fixtures in the club panel
- [x] Tactics: pitch plus squad list, drag between them, tabs for Formation, Shape, Defence, Attack, Set Pieces, Captain, role badges and movement arrows, pitch that redraws for each instruction, one-tap styles
- [x] Isometric club city from generated images (pan, zoom, tap to upgrade, growth with stadium level)
- [ ] City extras: building sites with a crane, match-day crowds and car parks, night lighting
- [x] ElevenLabs sounds: UI, stings, match, crowd loop

## Stage 2: menu contents
Club
- [x] Medical Centre, Contracts, Loan Watch
- [x] Team Report and Squad Gaps
- [ ] Dressing Room (hierarchy, morale, friendships, promises)
- [x] Fans (confidence, attendance trend, favourites, expectations)
- [x] Sponsors (shirt and stadium deals with targets)
- [ ] Match Analysis (shot maps, season trends)
- [x] Club Identity (kit colours, records, legends, all-time XI)
- [ ] Staff hiring

Manager
- [x] Philosophy (club DNA with bonuses)
- [x] Career Timeline, My Contract, Lifestyle (home, garage, business, language, local causes)
- [ ] Rival Managers
- [ ] Board Request (transfer funds, wages, stadium, new contract)
- [ ] Holiday mode, Game Status

World
- [x] Transfer Centre (rumours, done deals, records, deadline-day ticker)
- [ ] Awards (team of the week and season, golden boot, world player of the year)
- [x] Top 50 and Wonderkids, Manager Watch, Live Scores, League Standards

Search
- [x] Smart Lists (bargains, expiring, free agents, loan-listed, release clauses in budget)
- [x] Find Similar, Role Finder, Shortlist Alerts, saved filters, Staff Search, Find Club

Options
- [ ] Editor, Save Backup, Achievements, Hall of Fame, Manual, Scrapbook
- [ ] Custom dashboard panels

## Stage 3: depth
- [ ] Link lines and partnerships, tactical familiarity, opposition instructions, opponent overlay, strength and weakness readout
- [ ] Player personality (professionalism, determination, ambition, loyalty), conversations and promises
- [ ] Two-legged ties, extra time, kick-by-kick shoot-outs, derbies and rivalries
- [ ] Media and press conferences, breaking-news scenes for signings, deadline day, trophies and sackings, spoken headlines
- [ ] Transfer extras: pre-contracts, sell-on clauses, swaps, rumours
- [ ] Records and history, challenge modes, create-a-club, Quick Match, world options, difficulty, tutorial
- [ ] Manager portraits, scene backgrounds, trophy images

## Stage 4
- [ ] International football

## Art from generated images
- Facilities at five levels each: stadium, training ground, youth academy, medical centre, scouting office, commercial building
- City: housing (5), town buildings (6), open spaces and extras (7)
- Orientation: square base seen as a diamond with one corner at the bottom, entrance on the bottom-right edge, light from the top left, blue used only where the club colour should go
- Later: scene backgrounds, trophies, manager portraits, app icon, coaching badges and medals

## Added later
- [x] Lifestyle: salary, homes, garage, businesses, language, local causes
- [x] Investments: savings, rental property, shares; agent; media work
- [x] Club ownership: stakes with dividends, owner powers at 51%
- [x] Screen transitions, pulsing match-day button
- [x] Derbies (famous rivalries count double with fans)
- [x] Press conference before matches, with effects on morale, fans and board
- [x] Season Documentary (animated recap from the scrapbook)
- [ ] Deadline day as a live hour-by-hour event
- [ ] Rival managers who remember what you said
- [ ] Player stories (academy captain, veteran farewell, homesick wonderkid)
- [ ] Legends mode (retired players return as coaches or scouts)
- [ ] Family, holidays, legacy items (statue, stand), property abroad, owner while managing elsewhere
- [ ] Images for homes, cars, businesses and property; sponsor logos; manager portraits
- [x] Social feed with posts, reactions and effects
- [x] Newspaper front page for the appointment, trophy images, sponsor logos, app icon
- [x] Music player: put track_1.mp3, track_2.mp3, ... in assets/music

## World system (agreed, not built)
- Start flow: Continent > Nation > Competition > Club with a step bar, then choose up to five playable nations (the club's nation is locked on)
- Three tiers: playable (full simulation), background (real clubs and players, results estimated), placeholder (generated clubs and players)
- Placeholder players can be scouted and bought, but must not be a wonderkid loophole: cap their potential, make it uncertain until scouted in person, and price the good ones fairly
- Generated names drawn from real players of that nationality; nations generated only when first opened
- A background nation can be made playable between seasons; placeholder nations cannot
- Dataset check (men): full squads exist for England (4 divisions), Spain, Germany (3), Italy, France (2 each), Argentina (30 clubs), USA (30), Saudi Arabia, Belgium, Netherlands, Portugal, Turkey, Poland, Mexico, Denmark, South Korea, China, Sweden, Norway, Switzerland, Scotland, Austria, Ireland, India, Australia; partial for Greece, Czechia, Ukraine, Croatia, Cyprus and single clubs elsewhere; 40 South American clubs from the continental cups; 164 nationalities, 78 with 20 or more players
- Needs: nation and continent table, open-source flag set, continent pictures

## Polish pass (from phone feedback, 12 Nov)
- [x] True full screen, drawing under the camera cut-out
- [x] Three columns per page so pages are fuller
- [x] Player quick card when tapping a player in Tactics
- [x] Fixed action bar on player pages; correct club under the player's name
- [x] Lifestyle header showing current home, car and money
- [x] Transfers as a process: enquiry, club replies by message, fee talks (instalments, appearance add-on, sell-on), then player and agent talks (wage, length, squad role, signing-on fee, agent fee, release clause), newspaper on completion, rival bidders, lapsing agreements, broken role promises, counter-offers when selling
- [x] Player profile as six swipeable pages: profile with position map and all attributes, personal, positions and roles, contract, stats, manage
- [x] Player Search as a dense sortable table with three views, filters and paging
- [x] Dense rework: league table, player stats (four boards), cups (list + detail), scouting (reports on file), transfer market desk, job market
- [x] Dense rework: training (squad table with programme picker), finances (weekly ledger, 12-week balance, full wage bill), fixtures (season table with match panel, round view beside the league table), club view (profile, ratings, record, squad table), board room (objective, manager, career history), home (fuller Club and news panels)
- [ ] Dense rework still to do: the small pages in `hub.gd` and `lists.gd`
- [x] Lifestyle screen: overview, estate agent, car showroom with named cars and garage, businesses, weekly money in and out, net worth, holidays
- [x] Player personal details: personality, favoured club, languages, caps, career totals, season-by-season table
- [ ] Lifestyle later: family, legacy items (statue, stand), property abroad

## Fixes (v0.6.1, from phone feedback 12 Nov)
- [x] "Leave the game?" and every other confirm pop-up showed no buttons (bare `wrap()` in a lambda called the built-in maths function)
- [x] Camera cut-out: the rail background now runs to the screen edge and the icon column is narrower, so the strip beside the notch is no longer dead space
- [x] Tactics (v0.6.2): pitch takes the full height on every tab (tabs and buttons moved above the list), goalkeeper's name no longer cut off, right side no longer runs off the screen on notched phones
- [x] Player profile (on `dev`, not in an APK yet): all 18 attributes visible without scrolling; condition, morale, form, average rating, apps and goals moved up beside age, value and wage

## Tactics system (v0.7.0, on `dev`, not in an APK yet)
- [x] Team playstyles: Possession Game, Quick Counter, Long Ball Counter, Out Wide, Long Ball; manager proficiency in each; choosing one sets its default instructions; the six old quick presets are gone, the three save slots stay
- [x] Squad familiarity per player (new signings settle over about 10 to 15 matches) and a style fit number; fit is a bonus only
- [x] Defence 7 options, Attack 8 options, each with a trade-off in the match engine
- [x] Individual instructions: two attacking and two defensive slots (Counter Target, Attacking Full-back, Hug the Touchline, Anchoring, Tight Marking on a chosen opponent, Deep Line, Defensive Full-back)
- [x] 24 player skills, generated for every player, learnable in training (up to 8), used by the engine and named in commentary; on the profile, training, scout reports and as a search filter
- [x] Manager link-up plays: eight types, one at the start and one more per coaching badge, glowing line on the pitch, bronze/silver/gold with matches together; rival managers have a style and a link-up, shown before kick-off
- [x] Weekly form arrows and form type, injury resistance, weak foot on the wrong flank, Team of the Week
- [x] First-day setup (also on the first load of an older career): choose best playstyle, then first link-up
- [ ] The pitch drawing does not yet illustrate the new options (line of engagement, compactness, build-up and so on)

## Transfer system (v0.7.0, on `dev`)
- [x] Two-day deals: day 1 fee talks with the club across the table (patience bar, final offer, player swap, delegate to the assistant); day 2 the player and his agent come in
- [x] "What he wants" panel (essential and tradeable demands; fuller when he has been scouted), performance bonuses, agent patience bar
- [x] Recruitment brief for the chief scout, with playstyle and link-up filters
- [x] Loans with terms both ways: wage share, option or obligation to buy, playing-time promise, recall clause
- [x] Pre-contracts from 1 January; rivals can sign yours
- [x] Buy-back clauses and matching rights when selling players aged 23 or under; bigger clubs insist on a buy-back when selling you a prospect
- [x] Players with their own minds: unsettled after a refused bid from a bigger club, heads turned, agents offering players
- [x] Deadline day played hour by hour, with fees agreed that day bringing the player in the same evening

## Presentation (v0.7.0, on `dev`)
- [x] Football Dynasty 26 name, app icon and wordmark; one purple and gold colour scheme that no longer follows the club
- [x] Intro: ForgeFrame card, two-clip film, title over the last shot, Skip button
- [ ] Trophy and promotion films: the game plays `assets/video/win_league.ogv`, `win_cup.ogv`, `win_euro.ogv`, `win_promo.ogv` if present; clips still to come from Sudhi (Kling)

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
