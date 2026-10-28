# Audio-cues en geluidsvenster

**In één zin:** overal waar geluid hoort, roept de game een cue-id uit `audio/cues.json` aan; zolang er nog geen geluid is, toont het geluidsvenster (F2) wat je had moeten horen en schrijft een logboek het weg.

Schema: `tools/schemas/audio-cues.schema.json` (catalogus `audio/cues.json`). Cue-ids in content worden gecontroleerd via `cue_id` in `tools/schemas/common.schema.json`.

## Doel en pillar

- **Sfeer (1):** geluid draagt de helft van de sfeer. Door nu al overal cues aan te roepen, kan geluid later cue voor cue worden toegevoegd zonder iets aan de game te veranderen.
- Werkwijze: Martijn ziet bij het spelen in het venster of de verwachte geluidslaag klopt (definition of done: "het geluidsvenster gecontroleerd"). Het logboek bepaalt de geluidsbacklog.

## De catalogus (`audio/cues.json`)

```json
{
  "cues": [
    {
      "id": "deur.hout.open",
      "beschrijving": "Houten binnendeur gaat open, klink en scharnier",
      "laag": "effect",
      "soort": "eenmalig",
      "bron": "binnendeuren in woningen",
      "prioriteit": "hoog",
      "status": "verwacht"
    }
  ]
}
```

| Veld | Regels |
| --- | --- |
| `id` | punt-gescheiden snake_case-segmenten; eerste segment is de categorie: `voetstap`, `deur`, `lift`, `object`, `container`, `apparaat`, `ambience`, `muziek`, `stem`, `npc`, `ui`, `droom`, `wereld`. Specifiek naar algemeen: `voetstap.tegel.nat`, `deur.lift.open`. |
| `beschrijving` | wat je hoort, één zin (ontwerptekst, niet vertaald) |
| `laag` | `effect`, `voetstap`, `ambience`, `muziek`, `stem` (GDD) |
| `soort` | `eenmalig` (los geluid) of `doorlopend` (laag die klinkt tot hij gestopt wordt). Ambience en muziek zijn doorlopend; een tv die aan staat ook. |
| `bron` | waar het in de wereld vandaan komt; `systeem/interface` voor UI |
| `prioriteit` | `hoog`, `midden`, `laag` |
| `status` | `verwacht` (grijs), `placeholder` (geel), `klaar` (groen) |
| `bestand` | pad onder `game/assets/audio/`; verplicht zodra de status niet `verwacht` is |
| `context` | namen van waarden die de aanroeper meegeeft (bijv. `nat`); het venster toont ze |

Eigenaar van de catalogus is de geluidsontwerper. Wie een nieuwe cue nodig heeft (engineer, level-designer), voegt hem toe met status `verwacht`; de validator faalt anders.

## Regels

- A1. Code en content roepen alleen cue-ids aan, nooit bestanden. Alleen de audiolaag leest `bestand`.
- A2. Een cue-id die niet in de catalogus staat: in een ontwikkelbuild een foutregel in de log en een rode regel in het venster; in een release-build stil negeren. Tests falen erop (zie AC-03).
- A3. **Aanroepen** (interface van de audiolaag; waar die node in de boom hangt bepaalt de engineer binnen de regel "geen globale state behalve GameState en Content", bijv. als kind van GameState):
  - `cue(id: String, context: Dictionary = {})` voor `eenmalig`;
  - `start_laag(id: String, sleutel: String, context: Dictionary = {})` voor `doorlopend`; dezelfde sleutel opnieuw starten vervangt de vorige laag (bijv. sleutel `muziek` van `muziek.verkennen` naar `muziek.spanning`);
  - `stop_laag(sleutel: String)`;
  - `zet_ruimte(galm: String, raamfilter: bool)` bij binnenkomst van een kamer.
  - `cue()` met een `doorlopend`-id of `start_laag()` met een `eenmalig`-id is een fout (log + rood in het venster).
- A4. **Wie roept wat aan:**
  - Systemen: de standaardcues hieronder bij hun acties.
  - Kamers: `ambience` (lagen met sleutel `ambience.<n>`) bij binnenkomst gestart, bij vertrek gestopt; `galm` via `zet_ruimte`.
  - Scènes: `muziek` op sleutel `muziek`.
  - NPC's: `geluid` als laag zolang ze aanwezig zijn.
  - Objecten en uitgangen: hun `geluid`-overrides in plaats van de standaardcue.
  - Gebeurtenissen: `cue_start`, `cue_einde`.
  - Puzzelknopen en gespreksregels: `cue`-effect of `cue`-veld.
- A5. Tot er geluid is, speelt de audiolaag niets af maar doet verder alles (status bijhouden, venster, logboek). Een cue met status `placeholder` of `klaar` speelt het bestand af; ontbreekt het bestand, dan geldt A2.
- A6. **Raamfilter:** in het fundament altijd `uit`; het ramensysteem zet het later.

**Standaardcues die de fundamentsystemen aanroepen** (moeten met status `verwacht` in de catalogus staan voordat de systemen gebouwd worden):

| Cue-id | Soort | Wanneer |
| --- | --- | --- |
| `object.pak` | eenmalig | object gepakt |
| `object.leg` | eenmalig | object neergelegd |
| `object.in_container` | eenmalig | object in een container gestopt |
| `object.lees` | eenmalig | leestekst geopend (papier) |
| `container.open` | eenmalig | container geopend |
| `deur.open` | eenmalig | doorgang gelukt (standaard voor uitgangen) |
| `deur.geweigerd` | eenmalig | uitgang geweigerd |
| `lift.rit` | eenmalig | liftrit |
| `lift.geweigerd` | eenmalig | liftknop geweigerd |
| `ui.weiger` | eenmalig | sleepactie kan niet |
| `ui.highlight` | eenmalig | spatie: interactieve objecten oplichten |
| `ui.notitie.nieuw` | eenmalig | nieuw token in het notitieboek |
| `ui.klok.vooruit` | eenmalig | klok springt vooruit |
| `ui.klok.terug` | eenmalig | klok loopt terug |
| `ui.opslaan` | eenmalig | (auto)save geschreven |

Voetstap-cues (`voetstap.<vloer>[.nat]`) horen bij het voetsporensysteem (later); de looplogica roept vanaf nu al `voetstap.<vloer>` aan per stap met context `{"nat": 0.0}`, zodra kamers een `vloer` hebben.

## Het geluidsvenster (F2)

Alleen in ontwikkelbuilds (Godot-featuretag, bijv. `debug` of een eigen `ontwikkel`-tag). F2 schakelt het aan en uit; de stand blijft over kamerwissels. Het venster vangt geen klikken op (het spel blijft bespeelbaar) en pauzeert niets.

Indeling (halfdoorzichtig paneel, linksboven, monospace):

1. **Nu actief:** elke lopende laag op één regel: sleutel, cue-id, beschrijving (afgekort), context. Bovenaan de muziekstatus, bijv. `muziek  muziek.verkennen`.
2. **Gebeurtenissen:** de laatste 30 losse cues, nieuwste bovenaan: speeltijd (mm:ss), cue-id, context in Nederlandse notatie, bijv. `03:12  voetstap.tegel.nat  (nat 0,7)`. Herhaalde cue binnen 1 seconde: één regel met teller `×4`.
3. **Ruimte:** kamer-id, `galm`, `raamfilter aan/uit`.

Kleur per status: grijs = verwacht, geel = placeholder, groen = klaar, rood = onbekend of verkeerd aangeroepen. Hover over een regel toont `beschrijving` en `bron` volledig.

## Logboek

- Elke speelsessie in een ontwikkelbuild schrijft `user://logs/cues/<JJJJMMDD-HHMMSS>.jsonl` (echte datum: dit is een ontwikkelbestand, geen spellogica).
- Eén regel per aanroep: `{"t": 192.4, "soort": "cue|start|stop", "cue": "voetstap.tegel.nat", "sleutel": null, "context": {"nat": 0.7}, "kamer": "ch01_…", "scene": "ch01_…", "status": "verwacht"}`.
- Onbekende cues krijgen `"status": "onbekend"`.
- Een Python-tool (later, geluidsontwerper/QA) telt over alle logboeken hoe vaak elke cue klonk; zo volgt de backlog. Logboeken gaan niet in git.

## Edge cases

- Dezelfde laag twee keer starten met dezelfde sleutel en dezelfde cue: niets verandert (geen dubbele regel).
- `stop_laag` op een sleutel die niet loopt: niets, geen fout.
- Kamerwissel: ambience en NPC-lagen van de oude kamer stoppen vóór de nieuwe starten; muziek loopt door tot de scène wisselt.
- Opslaan en laden: lopende lagen worden niet opgeslagen maar opnieuw afgeleid uit kamer, scène en NPC's.
- Heel veel cues per seconde (voetstappen): het venster groepeert (×n), het logboek schrijft alles.

## Acceptatiecriteria

| # | Criterium |
| --- | --- |
| AC-01 | `audio/cues.json` valideert tegen het schema; een cue met status `klaar` zonder `bestand` faalt; een cue met status `verwacht` met `bestand` faalt. |
| AC-02 | De validator faalt als een cue-id in content (kamers, objecten, scènes, gebeurtenissen, NPC's, knopen, gesprekken, apparaten) niet in de catalogus staat. |
| AC-03 | Een test scant `game/**/*.gd` op cue-aanroepen met een letterlijke string en faalt als een id niet in de catalogus staat. |
| AC-04 | `cue("bestaat.niet")` in een ontwikkelbuild: geen crash, foutregel in de log, regel met status `onbekend` in het logboek. |
| AC-05 | `start_laag(a, "k")` gevolgd door `start_laag(b, "k")`: alleen b staat onder Nu actief. `stop_laag("k")`: niets meer onder die sleutel. |
| AC-06 | Bij binnenkomst van een kamer staan precies de `ambience`-cues van die kamer onder Nu actief; na vertrek niet meer. |
| AC-07 | Elke aanroep komt als één regel in het logboek met speeltijd, soort, cue-id, context, kamer en scène. |
| AC-08 | F2 toont en verbergt het venster in een ontwikkelbuild; in een release-export bestaat het venster niet en schrijft het spel geen logboek. |
| AC-09 | Het venster kleurt regels volgens de status in de catalogus (verwacht/placeholder/klaar/onbekend). |
| AC-10 | De standaardcues uit de tabel worden bij hun acties aangeroepen (gecontroleerd in de GUT-tests van inventaris, toegang en klok via het logboek of een testspion). |
