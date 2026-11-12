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
