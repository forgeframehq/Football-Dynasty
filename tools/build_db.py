#!/usr/bin/env python3
"""Builds data/db.json for Football Dynasty from a public EA FC ratings CSV.

Usage:  python3 tools/build_db.py path/to/players.csv

The CSV is the "EA SPORTS FC 27 Player Ratings" export (one row per player, columns such as
player_id, first_name, last_name, overall_rating, position, club, league, birthdate, pace...).
Only the five big leagues and their lower divisions are kept.
"""
import csv, json, sys, collections, os

LEAGUES = [
    # dataset name, display, short, country, tier
    ("Premier League", "Premier League", "PL", "England", 1),
    ("EFL Championship", "Championship", "CH", "England", 2),
    ("EFL League One", "League One", "L1", "England", 3),
    ("EFL League Two", "League Two", "L2", "England", 4),
    ("LALIGA EA SPORTS", "LaLiga", "LL", "Spain", 1),
    ("LALIGA HYPERMOTION", "LaLiga 2", "LL2", "Spain", 2),
    ("Serie A Enilive", "Serie A", "SA", "Italy", 1),
    ("Serie BKT", "Serie B", "SB", "Italy", 2),
    ("Bundesliga", "Bundesliga", "BL", "Germany", 1),
    ("Bundesliga 2", "2. Bundesliga", "BL2", "Germany", 2),
    ("3. Liga", "3. Liga", "3L", "Germany", 3),
    ("Ligue 1 McDonald's", "Ligue 1", "L1", "France", 1),
    ("Ligue 2 BKT", "Ligue 2", "L2", "France", 2),
]

# dataset club name;display name;short;primary;secondary;stadium
CLUBS = """
AFC Bournemouth;AFC Bournemouth;BOU;DA291C;000000;Vitality Stadium
Arsenal;Arsenal;ARS;EF0107;FFFFFF;Emirates Stadium
Aston Villa;Aston Villa;AVL;670E36;95BFE5;Villa Park
Brentford;Brentford;BRE;E30613;FFFFFF;Gtech Community Stadium
Brighton;Brighton & Hove Albion;BHA;0057B8;FFFFFF;Amex Stadium
Chelsea;Chelsea;CHE;034694;FFFFFF;Stamford Bridge
Coventry City;Coventry City;COV;59CBE8;FFFFFF;Coventry Building Society Arena
Crystal Palace;Crystal Palace;CRY;1B458F;C4122E;Selhurst Park
Everton;Everton;EVE;003399;FFFFFF;Hill Dickinson Stadium
Fulham;Fulham;FUL;FFFFFF;000000;Craven Cottage
Hull City;Hull City;HUL;F5A12D;000000;MKM Stadium
Ipswich;Ipswich Town;IPS;3A64A3;FFFFFF;Portman Road
Leeds United;Leeds United;LEE;FFFFFF;1D428A;Elland Road
Liverpool;Liverpool;LIV;C8102E;FFFFFF;Anfield
Man Utd;Manchester United;MUN;DA291C;000000;Old Trafford
Manchester City;Manchester City;MCI;6CABDD;FFFFFF;Etihad Stadium
Newcastle Utd;Newcastle United;NEW;241F20;FFFFFF;St James' Park
Nott'm Forest;Nottingham Forest;NFO;DD0000;FFFFFF;City Ground
Spurs;Tottenham Hotspur;TOT;FFFFFF;132257;Tottenham Hotspur Stadium
Sunderland;Sunderland;SUN;EB172B;FFFFFF;Stadium of Light
Birmingham City;Birmingham City;BIR;0033A0;FFFFFF;St Andrew's
Blackburn Rovers;Blackburn Rovers;BLB;009EE0;FFFFFF;Ewood Park
Bolton;Bolton Wanderers;BOL;FFFFFF;263C7E;Toughsheet Community Stadium
Bristol City;Bristol City;BRC;E21A23;FFFFFF;Ashton Gate
Burnley;Burnley;BUR;6C1D45;99D6EA;Turf Moor
Cardiff City;Cardiff City;CAR;0070B5;FFFFFF;Cardiff City Stadium
Charlton Ath;Charlton Athletic;CHA;D4021D;FFFFFF;The Valley
Derby County;Derby County;DER;FFFFFF;000000;Pride Park
Lincoln City;Lincoln City;LIN;D71920;FFFFFF;LNER Stadium
Middlesbrough;Middlesbrough;MID;E11B22;FFFFFF;Riverside Stadium
Millwall;Millwall;MIL;001D5E;FFFFFF;The Den
Norwich;Norwich City;NOR;FFF200;00A650;Carrow Road
Portsmouth;Portsmouth;POR;001489;FFFFFF;Fratton Park
Preston;Preston North End;PNE;FFFFFF;000055;Deepdale
QPR;Queens Park Rangers;QPR;1D5BA4;FFFFFF;Loftus Road
Sheffield Utd;Sheffield United;SHU;EE2737;FFFFFF;Bramall Lane
Southampton;Southampton;SOU;D71920;FFFFFF;St Mary's Stadium
Stoke City;Stoke City;STK;E03A3E;FFFFFF;bet365 Stadium
Swansea City;Swansea City;SWA;FFFFFF;000000;Swansea.com Stadium
Watford;Watford;WAT;FBEE23;ED2127;Vicarage Road
West Brom;West Bromwich Albion;WBA;122F67;FFFFFF;The Hawthorns
West Ham;West Ham United;WHU;7A263A;1BB1E7;London Stadium
Wolves;Wolverhampton Wanderers;WOL;FDB913;231F20;Molineux
Wrexham;Wrexham;WRE;E2001A;FFFFFF;Racecourse Ground
AFC Wimbledon;AFC Wimbledon;WIM;2A3FA0;FFD700;Plough Lane
Barnsley;Barnsley;BAR;D71920;FFFFFF;Oakwell
Blackpool;Blackpool;BPL;F68712;FFFFFF;Bloomfield Road
Bradford City;Bradford City;BRA;8C1D40;F5A800;Valley Parade
Bromley FC;Bromley;BRO;FFFFFF;000000;Hayes Lane
Burton Albion;Burton Albion;BRT;FFF200;000000;Pirelli Stadium
Cambridge Utd;Cambridge United;CAM;FBBA00;000000;Abbey Stadium
Doncaster;Doncaster Rovers;DON;D71920;FFFFFF;Eco-Power Stadium
Huddersfield;Huddersfield Town;HUD;0E63AD;FFFFFF;John Smith's Stadium
Leicester City;Leicester City;LEI;003090;FDBE11;King Power Stadium
Leyton Orient;Leyton Orient;LEY;D71920;FFFFFF;Brisbane Road
Luton Town;Luton Town;LUT;F78F1E;002D62;Kenilworth Road
MK Dons;MK Dons;MKD;FFFFFF;000000;Stadium MK
Mansfield Town;Mansfield Town;MAN;F5A300;1B3F94;Field Mill
Notts County;Notts County;NOT;000000;FFFFFF;Meadow Lane
Oxford United;Oxford United;OXF;FFF200;001F5B;Kassam Stadium
Peterborough;Peterborough United;PET;0E63AD;FFFFFF;London Road
Plymouth Argyle;Plymouth Argyle;PLY;00563F;FFFFFF;Home Park
Reading;Reading;REA;004494;FFFFFF;Select Car Leasing Stadium
Sheffield Wed;Sheffield Wednesday;SHW;4482D0;FFFFFF;Hillsborough
Stevenage;Stevenage;STE;D71920;FFFFFF;Lamex Stadium
Stockport;Stockport County;STO;0E4C92;FFFFFF;Edgeley Park
Wigan Athletic;Wigan Athletic;WIG;1D59AF;FFFFFF;Brick Community Stadium
Wycombe;Wycombe Wanderers;WYC;13294B;6CABDD;Adams Park
Accrington;Accrington Stanley;ACC;D71920;FFFFFF;Wham Stadium
Barnet;Barnet;BNT;F5A300;000000;The Hive
Bristol Rovers;Bristol Rovers;BRR;0E63AD;FFFFFF;Memorial Stadium
Cheltenham Town;Cheltenham Town;CHT;D71920;FFFFFF;Whaddon Road
Chesterfield;Chesterfield;CHF;1E3A8A;FFFFFF;SMH Group Stadium
Colchester;Colchester United;COL;0E63AD;FFFFFF;JobServe Community Stadium
Crawley Town;Crawley Town;CRA;D71920;FFFFFF;Broadfield Stadium
Crewe Alexandra;Crewe Alexandra;CRE;D71920;FFFFFF;Gresty Road
Exeter City;Exeter City;EXE;D71920;FFFFFF;St James Park
Fleetwood Town;Fleetwood Town;FLE;D71920;FFFFFF;Highbury Stadium
Gillingham;Gillingham;GIL;1E3A8A;FFFFFF;Priestfield
Grimsby Town;Grimsby Town;GRI;000000;FFFFFF;Blundell Park
Newport County;Newport County;NPT;F5A300;000000;Rodney Parade
Northampton;Northampton Town;NTH;7A1F3D;FFFFFF;Sixfields
Oldham Athletic;Oldham Athletic;OLD;0E63AD;FFFFFF;Boundary Park
Port Vale;Port Vale;PVA;FFFFFF;000000;Vale Park
Rochdale;Rochdale;ROC;1E3A8A;000000;Spotland
Rotherham Utd;Rotherham United;ROT;D71920;FFFFFF;New York Stadium
Salford City;Salford City;SAL;D71920;FFFFFF;Peninsula Stadium
Shrewsbury;Shrewsbury Town;SHR;1E3A8A;F5A300;Croud Meadow
Swindon Town;Swindon Town;SWI;D71920;FFFFFF;County Ground
Tranmere Rovers;Tranmere Rovers;TRA;FFFFFF;1E3A8A;Prenton Park
Walsall;Walsall;WAL;D71920;FFFFFF;Bescot Stadium
York City;York City;YOR;D71920;1E3A8A;LNER Community Stadium
Athletic Club;Athletic Club;ATH;EE2523;FFFFFF;San Mamés
Atlético de Madrid;Atlético Madrid;ATM;CB3524;FFFFFF;Riyadh Air Metropolitano
CA Osasuna;Osasuna;OSA;D91A21;0A346F;El Sadar
Celta;Celta Vigo;CEL;8AC3EE;FFFFFF;Balaídos
D. Alavés;Deportivo Alavés;ALA;0761AF;FFFFFF;Mendizorroza
Elche CF;Elche;ELC;FFFFFF;05642C;Martínez Valero
FC Barcelona;FC Barcelona;FCB;A50044;004D98;Spotify Camp Nou
Getafe CF;Getafe;GET;005999;FFFFFF;Coliseum
Levante UD;Levante;LEV;B4053F;005CA9;Ciutat de València
Málaga CF;Málaga;MLG;6CABDD;FFFFFF;La Rosaleda
R. Racing Club;Racing Santander;RAC;FFFFFF;0B7A3B;El Sardinero
RC Deportivo;Deportivo La Coruña;DEP;2E6DB4;FFFFFF;Riazor
RCD Espanyol;Espanyol;ESP;007FC8;FFFFFF;RCDE Stadium
Rayo Vallecano;Rayo Vallecano;RAY;FFFFFF;E53027;Vallecas
Real Betis;Real Betis;BET;00954C;FFFFFF;Benito Villamarín
Real Madrid;Real Madrid;RMA;FFFFFF;FEBE10;Santiago Bernabéu
Real Sociedad;Real Sociedad;RSO;0067B1;FFFFFF;Reale Arena
Sevilla FC;Sevilla;SEV;FFFFFF;D4021D;Ramón Sánchez-Pizjuán
Valencia CF;Valencia;VAL;FFFFFF;F18E00;Mestalla
Villarreal CF;Villarreal;VIL;FFE667;005187;Estadio de la Cerámica
AD Ceuta FC;AD Ceuta;CEU;FFFFFF;000000;Alfonso Murube
Albacete BP;Albacete;ALB;FFFFFF;7A1F3D;Carlos Belmonte
Burgos CF;Burgos;BUG;FFFFFF;000000;El Plantío
CD Castellón;Castellón;CAS;000000;FFFFFF;Castalia
CD Eldense;Eldense;ELD;1E3A8A;D71920;Nuevo Pepico Amat
CD Leganés;Leganés;LEG;0C4DA2;FFFFFF;Butarque
CD Tenerife;Tenerife;TEN;0C4DA2;FFFFFF;Heliodoro Rodríguez López
CE Sabadell FC;Sabadell;SAB;1E3A8A;FFFFFF;Nova Creu Alta
Celta Fortuna;Celta Fortuna;CFO;8AC3EE;FFFFFF;Balaídos
Cádiz CF;Cádiz;CAD;FFE500;0045A6;Nuevo Mirandilla
Córdoba CF;Córdoba;COR;FFFFFF;00824A;Nuevo Arcángel
FC Andorra;FC Andorra;AND;1E3A8A;FFD700;Estadi Nacional
Girona FC;Girona;GIR;CD2534;FFFFFF;Montilivi
Granada CF;Granada;GRA;C31632;FFFFFF;Nuevo Los Cármenes
R. Oviedo;Real Oviedo;OVI;004A9F;FFFFFF;Carlos Tartiere
R. Sporting;Sporting Gijón;SPG;D71920;FFFFFF;El Molinón
R. Valladolid CF;Real Valladolid;VLL;5B2D82;FFFFFF;José Zorrilla
RCD Mallorca;Mallorca;MLL;E20613;000000;Son Moix
Real Sociedad B;Real Sociedad B;RSB;0067B1;FFFFFF;Zubieta
SD Eibar;Eibar;EIB;8A1538;005BAC;Ipurua
UD Almería;Almería;ALM;EE1119;FFFFFF;UD Almería Stadium
UD Las Palmas;Las Palmas;LPA;FFE400;0055A4;Gran Canaria
AS Roma;AS Roma;ROM;8E1F2F;F0BC42;Stadio Olimpico
Bergamo Calcio;Atalanta;ATA;1E71B8;000000;Gewiss Stadium
Bologna;Bologna;BFC;1A2F48;A21C26;Renato Dall'Ara
Cagliari;Cagliari;CAG;B01028;002350;Unipol Domus
Como;Como;COM;0A4595;FFFFFF;Giuseppe Sinigaglia
Fiorentina;Fiorentina;FIO;482E92;FFFFFF;Artemio Franchi
Frosinone;Frosinone;FRO;FFE600;0055A4;Benito Stirpe
Genoa;Genoa;GEN;AD1919;002041;Luigi Ferraris
Juventus;Juventus;JUV;FFFFFF;000000;Allianz Stadium
Latium;Lazio;LAZ;87D8F7;FFFFFF;Stadio Olimpico
Lecce;Lecce;LEC;FFED00;D71920;Via del Mare
Lombardia FC;Inter;INT;0068A8;000000;San Siro
Milano FC;AC Milan;ACM;FB090B;000000;San Siro
Monza;Monza;MON;E4032E;FFFFFF;U-Power Stadium
Parma;Parma;PAR;FFFFFF;FFD200;Ennio Tardini
SSC Napoli;Napoli;NAP;12A0D7;FFFFFF;Diego Armando Maradona
Sassuolo;Sassuolo;SAS;00A752;000000;Mapei Stadium
Torino;Torino;TOR;8A1E03;FFFFFF;Olimpico Grande Torino
Udinese;Udinese;UDI;FFFFFF;000000;Bluenergy Stadium
Venezia;Venezia;VEN;000000;FF7A00;Pier Luigi Penzo
Arezzo;Arezzo;ARE;7A1F3D;FFFFFF;Città di Arezzo
Ascoli;Ascoli;ASC;FFFFFF;000000;Cino e Lillo Del Duca
Avellino;Avellino;AVE;00874B;FFFFFF;Partenio-Lombardi
Benevento;Benevento;BEN;FFD200;D71920;Ciro Vigorito
Carrarese Calcio;Carrarese;CRR;FFD200;1E3A8A;Stadio dei Marmi
Catanzaro;Catanzaro;CTZ;FFD200;D71920;Nicola Ceravolo
Cesena;Cesena;CES;FFFFFF;000000;Dino Manuzzi
Cremonese;Cremonese;CRM;8A8D8F;D71920;Giovanni Zini
Empoli;Empoli;EMP;0055A4;FFFFFF;Carlo Castellani
Entella;Virtus Entella;ENT;FFFFFF;6CABDD;Comunale di Chiavari
Hellas Verona;Hellas Verona;VER;FFD200;002F6C;Bentegodi
L. R. Vicenza;LR Vicenza;VIC;FFFFFF;D71920;Romeo Menti
Mantova;Mantova;MNT;FFFFFF;D71920;Danilo Martelli
Modena;Modena;MOD;FFD200;1E3A8A;Alberto Braglia
Padova;Padova;PAD;FFFFFF;D71920;Euganeo
Palermo;Palermo;PAL;F4A6C0;000000;Renzo Barbera
Pisa;Pisa;PIS;000000;0055A4;Arena Garibaldi
SS Juve Stabia;Juve Stabia;JST;FFD200;1E3A8A;Romeo Menti
Sampdoria;Sampdoria;SAM;1B5497;FFFFFF;Luigi Ferraris
Südtirol;Südtirol;SUD;FFFFFF;D71920;Druso
1. FC Köln;1. FC Köln;KOE;FFFFFF;ED1C24;RheinEnergieStadion
1. FSV Mainz 05;Mainz 05;M05;C3141E;FFFFFF;Mewa Arena
Borussia Dortmund;Borussia Dortmund;BVB;FDE100;000000;Signal Iduna Park
FC Augsburg;FC Augsburg;FCA;BA3733;46714D;WWK Arena
FC Bayern München;Bayern München;BAY;DC052D;FFFFFF;Allianz Arena
FC Schalke 04;Schalke 04;S04;004D9D;FFFFFF;Veltins-Arena
Frankfurt;Eintracht Frankfurt;SGE;E1000F;000000;Deutsche Bank Park
Hamburger SV;Hamburger SV;HSV;0A3F86;FFFFFF;Volksparkstadion
Leverkusen;Bayer 04 Leverkusen;B04;E32221;000000;BayArena
M'gladbach;Borussia Mönchengladbach;BMG;FFFFFF;1A9F4B;Borussia-Park
RB Leipzig;RB Leipzig;RBL;DD0741;FFFFFF;Red Bull Arena
SC Freiburg;SC Freiburg;SCF;D40019;000000;Europa-Park Stadion
SC Paderborn 07;SC Paderborn;SCP;005CA9;000000;Home Deluxe Arena
SV Elversberg;SV Elversberg;ELV;FFFFFF;000000;Ursapharm-Arena
SV Werder Bremen;Werder Bremen;SVW;1D9053;FFFFFF;Weserstadion
TSG Hoffenheim;TSG Hoffenheim;TSG;1961B5;FFFFFF;PreZero Arena
Union Berlin;Union Berlin;FCU;EB1923;FFD200;An der Alten Försterei
VfB Stuttgart;VfB Stuttgart;VFB;FFFFFF;E32219;MHPArena
1. FC Magdeburg;1. FC Magdeburg;FCM;0E63AD;FFFFFF;Avnet Arena
1. FC Nürnberg;1. FC Nürnberg;FCN;AD1732;000000;Max-Morlock-Stadion
Arminia Bielefeld;Arminia Bielefeld;DSC;004E95;FFFFFF;SchücoArena
Braunschweig;Eintracht Braunschweig;EBS;FFD200;0055A4;Eintracht-Stadion
Dynamo Dresden;Dynamo Dresden;SGD;FFD200;000000;Rudolf-Harbig-Stadion
Energie Cottbus;Energie Cottbus;FCE;D71920;FFFFFF;LEAG Energie Stadion
FC St. Pauli;FC St. Pauli;STP;624839;FFFFFF;Millerntor-Stadion
Fürth;Greuther Fürth;SGF;FFFFFF;009932;Sportpark Ronhof
Hannover 96;Hannover 96;H96;1D9053;000000;Heinz von Heiden Arena
Heidenheim;1. FC Heidenheim;HDH;E2001A;0046AA;Voith-Arena
Hertha BSC;Hertha BSC;BSC;005CA9;FFFFFF;Olympiastadion
Holstein Kiel;Holstein Kiel;KSV;0055A4;FFFFFF;Holstein-Stadion
Kaiserslautern;1. FC Kaiserslautern;FCK;D71920;FFFFFF;Fritz-Walter-Stadion
Karlsruher SC;Karlsruher SC;KSC;0055A4;FFFFFF;BBBank Wildpark
SV Darmstadt 98;Darmstadt 98;D98;004E9E;FFFFFF;Merck-Stadion am Böllenfalltor
VfL Bochum 1848;VfL Bochum;BOC;005CA9;FFFFFF;Vonovia Ruhrstadion
VfL Osnabrück;VfL Osnabrück;OSN;5B2D82;FFFFFF;Bremer Brücke
VfL Wolfsburg;VfL Wolfsburg;WOB;65B32E;FFFFFF;Volkswagen Arena
Aleman. Aachen;Alemannia Aachen;AAC;FFD200;000000;Tivoli
Düsseldorf;Fortuna Düsseldorf;F95;E2001A;FFFFFF;Merkur Spiel-Arena
FC Hansa Rostock;Hansa Rostock;FCH;0055A4;FFFFFF;Ostseestadion
FC Ingolstadt 04;FC Ingolstadt 04;FCI;D71920;000000;Audi Sportpark
FC Würzburger Kickers;Würzburger Kickers;FWK;D71920;FFFFFF;Akon Arena
Jahn Regensburg;Jahn Regensburg;SSV;D71920;FFFFFF;Jahnstadion
MSV Duisburg;MSV Duisburg;MSV;0055A4;FFFFFF;Schauinsland-Reisen-Arena
Preußen Münster;Preußen Münster;PRM;000000;00874B;Preußenstadion
Rot-Weiss Essen;Rot-Weiss Essen;RWE;D71920;FFFFFF;Stadion an der Hafenstraße
SC Fortuna Köln;Fortuna Köln;FOK;D71920;FFFFFF;Südstadion
SC Verl;SC Verl;SCV;000000;FFFFFF;Sportclub Arena
SG Sonnenhof Großaspach;Sonnenhof Großaspach;SGS;D71920;000000;WIRmachenDRUCK Arena
SV Meppen;SV Meppen;SVM;0055A4;FFFFFF;Hänsch-Arena
SV Waldhof;Waldhof Mannheim;WMA;0055A4;000000;Carl-Benz-Stadion
Saarbrücken;1. FC Saarbrücken;FCS;0055A4;000000;Ludwigsparkstadion
TSG Hoffenheim II;TSG Hoffenheim II;TS2;1961B5;FFFFFF;Dietmar-Hopp-Stadion
TSV Havelse;TSV Havelse;HAV;D71920;FFFFFF;Wilhelm-Langrehr-Stadion
VfB Stuttgart II;VfB Stuttgart II;VF2;FFFFFF;E32219;Gazi-Stadion
Viktoria Köln;Viktoria Köln;VIK;D71920;000000;Sportpark Höhenberg
Wehen Wiesbaden;Wehen Wiesbaden;WWI;D71920;000000;Brita-Arena
AJ Auxerre;AJ Auxerre;AJA;FFFFFF;0055A4;Abbé-Deschamps
AS Monaco;AS Monaco;ASM;E51B22;FFFFFF;Stade Louis II
Angers SCO;Angers SCO;SCO;000000;FFFFFF;Raymond Kopa
ESTAC Troyes;Troyes;EST;0055A4;FFFFFF;Stade de l'Aube
FC Lorient;FC Lorient;FCL;F58113;000000;Stade du Moustoir
Havre AC;Le Havre;HAC;6CABDD;1E3A8A;Stade Océane
LOSC Lille;Lille;LIL;E01E13;20325F;Stade Pierre-Mauroy
Le Mans FC;Le Mans;LEM;D71920;FFD200;Stade Marie-Marvingt
OGC Nice;OGC Nice;NIC;CC0000;000000;Allianz Riviera
OL;Olympique Lyonnais;OL;FFFFFF;DA001A;Groupama Stadium
OM;Olympique de Marseille;OM;FFFFFF;2FAEE0;Stade Vélodrome
Paris FC;Paris FC;PFC;14265A;FFFFFF;Stade Jean-Bouin
Paris SG;Paris Saint-Germain;PSG;004170;DA291C;Parc des Princes
RC Lens;RC Lens;RCL;E8B100;D71920;Stade Bollaert-Delelis
Stade Brestois 29;Brest;SB29;E2001A;FFFFFF;Stade Francis-Le Blé
Stade Rennais FC;Rennes;REN;E13327;000000;Roazhon Park
Strasbourg;RC Strasbourg;RCS;009FE3;FFFFFF;Stade de la Meinau
Toulouse FC;Toulouse;TFC;5B2D82;FFFFFF;Stadium de Toulouse
AS Nancy Lorraine;Nancy;NAL;D71920;FFFFFF;Marcel-Picot
AS Saint-Étienne;Saint-Étienne;ASSE;009640;FFFFFF;Geoffroy-Guichard
Clermont Foot 63;Clermont Foot;CF63;C8102E;1E3A8A;Gabriel-Montpied
Dijon Football Côte d’Or;Dijon;DFCO;D71920;FFFFFF;Gaston-Gérard
En Avant Guingamp;Guingamp;EAG;D71920;000000;Roudourou
FC Annecy;Annecy;ANN;D71920;FFFFFF;Parc des Sports
FC Metz;Metz;MET;6E0F28;FFFFFF;Saint-Symphorien
FC Nantes;Nantes;NAN;FFE500;00874B;La Beaujoire
FC Sochaux-Montbéliard;Sochaux;SOC;FFD200;1E3A8A;Stade Bonal
Grenoble Foot 38;Grenoble;GF38;0055A4;FFFFFF;Stade des Alpes
Laval MFC;Stade Lavallois;LAV;F58113;000000;Francis-Le Basser
Montpellier;Montpellier;MHSC;F58113;1E3A8A;Stade de la Mosson
Pau FC;Pau;PAU;FFD200;1E3A8A;Nouste Camp
Red Star FC;Red Star;RED;00874B;FFFFFF;Stade Bauer
Rodez AF;Rodez;RAF;D71920;FFD200;Paul-Lignon
Stade de Reims;Reims;SDR;D71920;FFFFFF;Auguste-Delaune
US Boulogne;Boulogne;USB;D71920;000000;Stade de la Libération
USL Dunkerque;Dunkerque;USLD;0055A4;FFFFFF;Marcel-Tribut
"""


# Rest-of-Europe leagues: the strongest clubs join as continental opponents and transfer targets
ROE = [
    ("Eredivisie", "Eredivisie", "Netherlands"), ("Liga Portugal", "Liga Portugal", "Portugal"), ("Trendyol Süper Lig", "Süper Lig", "Türkiye"),
    ("1A Pro League", "Belgian Pro League", "Belgium"), ("Scottish Premiership", "Scottish Premiership", "Scotland"),
    ("Ö. Bundesliga", "Austrian Bundesliga", "Austria"), ("Brack Super League", "Swiss Super League", "Switzerland"),
    ("SUPERLIGA", "Romanian SuperLiga", "Romania"), ("Hellas Liga", "Super League Greece", "Greece"), ("Česká Liga", "Czech First League", "Czechia"),
    ("Ukrayina Liha", "Ukrainian Premier League", "Ukraine"), ("Liga Hrvatska", "HNL", "Croatia"), ("Ekstraklasa", "Ekstraklasa", "Poland"),
    ("Allsvenskan", "Allsvenskan", "Sweden"), ("Eliteserien", "Eliteserien", "Norway"), ("Liga Cyprus", "Cypriot First Division", "Cyprus"),
    ("Magyar Liga", "NB I", "Hungary"), ("Liga Bulgaria", "Bulgarian First League", "Bulgaria"), ("Liga Azerbaijan", "Azerbaijan Premier League", "Azerbaijan"),
]
ROE_CLUBS = 64
ROE_META = """
Fenerbahçe;Fenerbahçe;FEN;FFED00;163962
FC Porto;FC Porto;FCP;00428C;FFFFFF
Galatasaray;Galatasaray;GAL;A90432;FDB912
SL Benfica;Benfica;SLB;E83030;FFFFFF
Sporting CP;Sporting CP;SPO;008057;FFFFFF
PSV;PSV;PSV;ED1C24;FFFFFF
Olympiacos FC;Olympiacos;OLY;D2232A;FFFFFF
Beşiktaş;Beşiktaş;BJK;000000;FFFFFF
Ajax;Ajax;AJX;D2122E;FFFFFF
AEK Athens;AEK Athens;AEK;FFD200;000000
Trabzonspor;Trabzonspor;TS;7C162E;4FA4D9
Feyenoord;Feyenoord;FEY;E2001A;FFFFFF
SC Braga;SC Braga;SCB;D1232A;FFFFFF
Panathinaikos;Panathinaikos;PAO;007A3D;FFFFFF
Club Brugge;Club Brugge;BRU;0A4DA2;000000
Celtic;Celtic;CEL;018749;FFFFFF
Slavia Praha;Slavia Praha;SLA;D2232A;FFFFFF
PAOK FC;PAOK;PAOK;000000;FFFFFF
KRC Genk;KRC Genk;GNK;0055A4;FFFFFF
AZ;AZ Alkmaar;AZ;D2122E;FFFFFF
Rangers;Rangers;RAN;1B458F;FFFFFF
R. Union St.-G.;Union Saint-Gilloise;USG;FFE500;0A4DA2
N.E.C. Nijmegen;NEC Nijmegen;NEC;D2122E;007A3D
FC Twente;FC Twente;TWE;D2122E;FFFFFF
Dynamo Kyiv;Dynamo Kyiv;DYN;FFFFFF;0A4DA2
RSC Anderlecht;Anderlecht;AND;5B2D82;FFFFFF
Shakhtar Donetsk;Shakhtar Donetsk;SHA;F58113;000000
Sparta Praha;Sparta Praha;SPA;8A1538;FFFFFF
FK Bodø/Glimt;Bodø/Glimt;BOD;FFE500;000000
Viktoria Plzeň;Viktoria Plzeň;PLZ;D2122E;0A4DA2
PFC Ludogorets;Ludogorets;LUD;007A3D;FFFFFF
Dinamo Zagreb;Dinamo Zagreb;DZG;0A4DA2;FFFFFF
Lech Poznań;Lech Poznań;LPO;0A4DA2;FFFFFF
Başakşehir;Başakşehir;IBFK;F58113;1B2A49
BSC Young Boys;Young Boys;YB;FFE500;000000
KAA Gent;KAA Gent;GNT;0A4DA2;FFFFFF
FC Famalicão;Famalicão;FAM;0A4DA2;FFFFFF
RB Salzburg;RB Salzburg;RBS;FFFFFF;D2122E
FC Utrecht;FC Utrecht;UTR;D2122E;FFFFFF
Ferencvárosi TC;Ferencváros;FTC;007A3D;FFFFFF
Viking FK;Viking FK;VIK;0A2A66;FFFFFF
Arouca;Arouca;ARO;FFE500;0A4DA2
Qarabağ FK;Qarabağ;QAR;000000;FFFFFF
Standard Liège;Standard Liège;STL;D2122E;FFFFFF
Çorum Futbol Kulübü;Çorum FK;COR;D2122E;000000
Hearts;Hearts;HEA;8A1538;FFFFFF
Univ. Craiova;Universitatea Craiova;UCV;0A4DA2;FFFFFF
Estoril Praia;Estoril Praia;EST;FFE500;0A4DA2
Widzew Łódź;Widzew Łódź;WID;D2122E;FFFFFF
Hajduk Split;Hajduk Split;HAJ;FFFFFF;0A4DA2
FC Lugano;FC Lugano;LUG;000000;FFFFFF
KV Mechelen;KV Mechelen;MEC;FFE500;D2122E
Omonia FC;Omonia;OMO;007A3D;FFFFFF
Samsunspor;Samsunspor;SMS;D2122E;FFFFFF
Servette FC;Servette;SER;8A1538;FFFFFF
LASK;LASK;LASK;000000;FFFFFF
Vitória SC;Vitória SC;VSC;FFFFFF;000000
Raków;Raków Częstochowa;RAK;D2122E;0A4DA2
Górnik Zabrze;Górnik Zabrze;GOR;0A4DA2;D2122E
STVV;Sint-Truiden;STV;FFE500;0A4DA2
APOEL FC;APOEL;APO;FFE500;0A4DA2
Konyaspor;Konyaspor;KON;007A3D;FFFFFF
SK Rapid;Rapid Wien;RAP;007A3D;FFFFFF
FC Basel 1893;FC Basel;BAS;D2122E;0A4DA2
"""
PALETTE = ["D2122E", "0A4DA2", "007A3D", "F58113", "5B2D82", "FFD200", "1B2A49", "8A1538"]


def attrs(r):
    g = lambda k: int(r[k] or 0)
    return [g("attacking_finishing"), g("power_long_shots"), g("attacking_heading_accuracy"), g("attacking_crossing"), g("attacking_short_passing"),
            g("mentality_vision"), g("skill_dribbling"), (g("movement_acceleration") + g("movement_sprint_speed")) // 2, g("power_stamina"), g("power_strength"),
            (g("defending_standing_tackle") + g("defending_sliding_tackle")) // 2, (g("defending_awareness") + g("mentality_interceptions")) // 2,
            g("mentality_positioning"), g("mentality_composure"), g("mentality_aggression"), g("skill_long_passing"), g("skill_fk_accuracy"), g("mentality_penalties")]


def main():
    src = sys.argv[1]
    out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(__file__), "..", "data", "db.json")
    meta = {}
    for line in CLUBS.strip().splitlines():
        n, disp, short, c1, c2, stad = line.split(";")
        meta[n] = (disp, short, c1, c2, stad)
    rows = [r for r in csv.DictReader(open(src, encoding="utf-8")) if r["gender"].startswith("Men")]
    lg_index = {l[0]: i for i, l in enumerate(LEAGUES)}
    leagues = [{"name": l[1], "short": l[2], "country": l[3], "tier": l[4], "roe": False} for l in LEAGUES]
    # pick the strongest rest-of-Europe clubs
    roe_names = {l[0] for l in ROE}
    by_club = collections.defaultdict(list)
    for r in rows:
        if r["league"] in roe_names:
            by_club[(r["league"], r["club"])].append(int(r["overall_rating"]))
    rank = sorted(by_club, key=lambda k: -sum(sorted(by_club[k], reverse=True)[:16]) / min(16, len(by_club[k])))[:ROE_CLUBS]
    roe_keep = set(rank)
    for l in ROE:
        if any(k[0] == l[0] for k in roe_keep):
            lg_index[l[0]] = len(leagues)
            leagues.append({"name": l[1], "short": l[1][:3].upper(), "country": l[2], "tier": 1, "roe": True})
    for line in ROE_META.strip().splitlines():
        n, disp, short, c1, c2 = line.split(";")
        meta[n] = (disp, short, c1, c2, "")
    clubs, club_index, players = [], {}, []
    missing = set()
    # main-league clubs first so their ids never change when the rest-of-Europe list does
    rows.sort(key=lambda r: 1 if r["league"] in roe_names else 0)
    for r in rows:
        if r["league"] not in lg_index:
            continue
        key = (r["league"], r["club"])
        if r["league"] in roe_names and key not in roe_keep:
            continue
        if key not in club_index:
            m = meta.get(r["club"])
            if not m:
                missing.add(r["club"])
                h = sum(ord(ch) for ch in r["club"])
                m = (r["club"], "".join(ch for ch in r["club"] if ch.isalpha())[:3].upper(), PALETTE[h % 8], "FFFFFF" if h % 3 else "000000", "")
            club_index[key] = len(clubs)
            clubs.append({"name": m[0], "short": m[1], "lg": lg_index[r["league"]], "c1": m[2], "c2": m[3], "stadium": m[4]})
        y, mo, d = (int(x) for x in r["birthdate"].split("-"))
        players.append([
            int(r["player_id"]), r["first_name"].strip(), r["last_name"].strip(), r["common_name"].strip(),
            club_index[key], r["position"], r["alternate_positions"].strip(), r["nationality"], y, mo, d,
            int(r["overall_rating"]),
            int(r["pace"]), int(r["shooting"]), int(r["passing"]), int(r["dribbling"]), int(r["defending"]), int(r["physicality"]),
            r["preferred_foot"][:1], int(r["skill_moves"]), int(r["weak_foot"]),
        ] + attrs(r))
    # name pools for generated youth players
    firsts, lasts = collections.defaultdict(collections.Counter), collections.defaultdict(collections.Counter)
    for r in rows:
        f, l = r["first_name"].strip(), r["last_name"].strip()
        if f and l and len(f) < 14 and len(l) < 16 and " " not in f:
            firsts[r["nationality"]][f] += 1
            lasts[r["nationality"]][l.split(" ")[0]] += 1
    names = {}
    for nat in firsts:
        if sum(firsts[nat].values()) >= 40:
            names[nat] = {"f": [n for n, _ in firsts[nat].most_common(70)], "l": [n for n, _ in lasts[nat].most_common(110)]}
    db = {"season": 2026, "leagues": leagues, "clubs": clubs, "players": players, "names": names}
    os.makedirs(os.path.dirname(out), exist_ok=True)
    json.dump(db, open(out, "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
    print(f"{len(leagues)} leagues, {len(clubs)} clubs, {len(players)} players, {len(names)} name pools -> {out}")
    if missing:
        print("clubs without metadata:", sorted(missing))


if __name__ == "__main__":
    main()
