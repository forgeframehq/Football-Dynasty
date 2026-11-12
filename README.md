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

- **13 leagues, 266 clubs, ~7,200 real players** (2026/27 squads): Premier League → League Two, LaLiga + LaLiga 2,
  Serie A + B, Bundesliga → 3. Liga, Ligue 1 + 2, with promotion, relegation and play-offs.
- **Career hub** – calendar-driven "Continue" flow, board objective and confidence, inbox, news, job market, sacking.
- **Match day** – pre-match briefing, live minute-by-minute match with commentary, ball tracker, live stats,
  speed control, substitutions and tactical changes, full-time report with player ratings. Or quick-sim.
- **Tactics** – 8 formations, tap-to-swap line-up on the pitch, mentality / pressing / tempo, fitness and suspensions.
- **Transfers** – search and shortlist, fee and contract negotiations, incoming bids for your players,
  AI-to-AI transfers, free agents, two windows per season.
- **Squad building** – player growth and decline, potential, morale, form, injuries, contract renewals,
  retirements and yearly youth intake.
- **Finances** – transfer budget, wage budget, prize money each season.
- Autosave after every match / continue.

## Project layout

```
data/db.json            leagues, clubs, players (built by tools/build_db.py)
data/icons.json         UI icon set (Lucide, ISC licence)
assets/fonts            Barlow + Barlow Condensed (SIL OFL)
scripts/game.gd         autoload G: career state, time, line-ups, save/load
scripts/match_engine.gd minute-by-minute match simulation
scripts/leagues.gd      fixtures, tables, play-offs, season rollover
scripts/transfers.gd    market logic and AI transfers
scripts/ui.gd           autoload UI: design system and widgets
scripts/main.gd         app shell: screen stack, bottom nav, sheets
scripts/screens/        one script per screen
scripts/widgets/        custom-drawn badge, pitch, player token, bar
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
