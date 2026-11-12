# Football Dynasty

A portrait football career-manager for Android, built with Godot 4.7 (GDScript, GL Compatibility renderer).
Personal project — real league, club and player names are used, so it is **not for distribution**.

## Install on your phone

Every push to `main` builds an APK with GitHub Actions:

1. Open the repo's **Releases → Latest build** and download `FootballDynasty.apk`
   (or grab it from the workflow run under **Actions → Build Android APK → Artifacts**).
2. Open the file on your Android device and allow "install unknown apps" when asked.

Builds are signed with the debug key in `tools/debug.keystore`, so new builds install over old ones and keep your save.

## What's in the game

- **13 playable leagues, 266 clubs, ~7,200 real players** (2026/27 squads): Premier League → League Two, LaLiga + LaLiga 2,
  Serie A + B, Bundesliga → 3. Liga, Ligue 1 + 2, with promotion, relegation and play-offs.
  A further 64 clubs from the rest of Europe (Benfica, Ajax, Celtic, Galatasaray…) appear in European
  competitions and the transfer market.
- **Competitions** – six domestic cups, Champions League, Europa League, Conference League, pre-season friendlies.
- **Manager** – nationality, coaching badge, playing career and four coaching attributes; study for the next badge.
- **Match day** – opposition report, live 2D match with all 22 players, commentary, momentum graph, live scores and
  "as it stands" table, shot map, touchline shouts, half-time team talk, substitutions, presets, key-highlights speed.
- **Tactics** – drag players anywhere on the pitch, 28 player roles with suitability, mentality / pressing / tempo /
  width / defensive line / passing / counter-attack, captain and set-piece takers, three saved presets.
- **Squad** – five list views, depth chart, squad status, numbers, player comparison, youth team, loans.
- **Transfers** – search, shortlist, fee and contract negotiation, release clauses, loans, incoming bids,
  AI transfers, free agents, deadline day.
- **Scouting** – other clubs' players show a potential range until scouted; standing scouting assignments.
- **Training** – team focus and intensity, individual programmes, position retraining.
- **Club** – 3D campus with stadium and five facilities (levels 1–5) that change as you upgrade them;
  weekly finances from sponsorship, gates, TV, wages and upkeep.
- **Career** – board objective and confidence, sacking and job offers, player growth and decline over 18 attributes,
  morale and unhappy players, injuries, youth intake, season awards, trophy room.
- Three save slots, autosave, sound effects.

## Project layout

```
data/db.json            leagues, clubs, players (built by tools/build_db.py)
data/icons.json         UI icon set (Lucide, ISC licence)
assets/fonts            Barlow + Barlow Condensed (SIL OFL)
scripts/game.gd         autoload G: career state, time, line-ups, save/load
scripts/match_engine.gd minute-by-minute match simulation
scripts/leagues.gd      fixtures, tables, play-offs, season rollover
scripts/transfers.gd    market logic and AI transfers
scripts/comps.gd        domestic cups and European competitions
scripts/club_ops.gd     facilities, finances, training, scouting, loans, manager profile
scripts/roles.gd        detailed attributes and player roles
scripts/ui.gd           autoload UI: design system and widgets
scripts/main.gd         app shell: screen stack, bottom nav, sheets
scripts/screens/        one script per screen
scripts/widgets/        custom-drawn badge, pitch, player token, bar
assets/models           stadium, facility and surroundings models (GLB, levels 1-5)
assets/sfx              generated sound effects
dev/                    headless season soak test, screenshot + touch test tools
```

Club badges are drawn procedurally from club colours — no real crests are included.

## Working on it

Open the folder in Godot 4.7+. Useful commands:

```
godot --headless --path . -- --selftest 3      # simulate 3 full seasons, print calibration numbers
godot --path . --resolution 720x1560 -- --shots # walk every screen and save screenshots to /tmp/shots
python3 tools/build_db.py players.csv           # rebuild data/db.json from an EA FC ratings CSV export
```
