# Code-review fundament-3d

Reviewer: code-reviewer · Branch: `iteratie/fundament-3d` · Diff `main...HEAD` (game, tools, tests, .github) · 2026-10-28

Gedraaid: `python tools/test_godot.py` groen (GUT 119/119), pytest 97 groen, `validate.py --all` groen. Playthroughs van eerdere hoofdstukken: die bestaan niet (geen `tests/playthroughs/`, `content/` heeft geen spelcontent); de regressiecheck is de bestaande GUT-suite (objecten, toegang, state, klok, audio), die groen blijft. `object_boom.gd` is de enige wijziging aan bestaande logica (`vrije_tegel` telt `geblokkeerd` uit de kamerdata mee); geen regressie gevonden. Het blokkerende punt B1 is nagebootst met een wegwerptest buiten de repo (foutmelding `Invalid type in function aabb_van ... previously freed`, elke frame).

Opbouw klopt met de spec: Vak, KamerRaster, Loper, CameraStand, Kwaliteit en Interactie zijn zuiver (geen Node3D), de weergave bouwt uit logica en content, alle bestanden blijven onder 300 regels (grootste: `kamer_weergave_basis.gd` 230; `test_kamerweergave.gd` 296 zit er vlak onder). Vak-conversie (W3), A* met 8 richtingen zonder hoeken afsnijden en de camera-afstand (W11) kloppen.

## Blokkerend

**B1. Crash-lus als het object onder de cursor wordt gepakt.** `game/weergave/kamer_weergave_basis.gd:123-125` en `:141-144`; `game/weergave/kamer_bouwer.gd:46-49`. `_objecten_veranderd` controleert `is_instance_valid(hover["node"])` vóór `KamerBouwer.zet_objecten`, en juist die roept `free()` aan op de node van het weggepakte object. `hover` blijft dan naar een vrijgegeven node wijzen en `tik` roept elke frame `aabb_van(hover["node"])` aan: scriptfout per frame, vergrootglas en naamlabel blijven hangen. Dit gebeurt bij het normale spelpad: klik op een pakbaar object, Richard loopt erheen, pakt het, de cursor staat nog op het object. Test `test_object_pakken_haalt_node_weg_en_maakt_vak_vrij` zet geen hover en mist dit. Voorstel: na `zet_objecten` hover wissen (en `ui.toon_naam("")`, `glas.verberg()`) als de node niet meer geldig is, of vóór het vrijgeven `hover_op({})` aanroepen; voeg een test toe met hover, pakken, 60 ticks. Issue aangemaakt.

## Moet

- **M1. Weergave volgt een geladen save niet.** `kamer_weergave_basis.gd:37-58` (en `kamer_weergave.gd:237-243`). `Spel.spel_geladen` (`opslaan.gd:189`) wordt nergens door de weergave beluisterd (alleen `main.gd:37` ververst de klok). Na `laad()` toont de weergave de oude kamer; `loper`, `root.raster`, `hover`, `_doel` en `staat` (bijv. `closeup`) blijven oud. Voorstel: in `start` `spel.spel_geladen` koppelen aan `bouw_kamer(spel.kamer)` plus reset van `loper`, `hover`, `_doel`, `closeup`, `overgang`; test: opslaan in kantoor, laden in hal, kamer en Richard kloppen. Zolang er geen laadmenu is valt dit niet op; het hoort bij "opslaan/laden van nieuwe state".
- **M2. Neergelegd object krijgt de `stand` van zijn beginplaatsing.** `kamer_bouwer.gd:53-57`. De plaatsing wordt op item-id gezocht, zonder te kijken of het object nog op de beginpositie ligt. Een pakbaar object dat op een bureau begon (`stand.hoogte` 0,75, `dx`, `dz`, `draai`) zweeft na neerleggen elders op 0,75 m. Spec (Edge cases): "Neergelegd object: op het vakmidden, `stand` 0". Voorstel: stand alleen toepassen als `objecten.positie[item]` gelijk is aan de plaatsingspositie; test met een pakbaar object met `stand`.
- **M3. NPC die verschijnt of verdwijnt wordt niet verwerkt.** `kamer_weergave_basis.gd:53` luistert alleen op `object_verplaatst`; `kamer_bouwer.gd:35-36` bouwt NPC-nodes alleen bij het opbouwen. Spec Edge cases: een NPC met `aanwezig` maakt een vak (on)beloopbaar en een lopend pad wordt opnieuw berekend. Nu blijft het raster verouderd, Richard kan door een nieuwe NPC lopen en een vertrokken NPC blijft staan. Voorstel: een signaal van het state-systeem bij flag-/tokenwijziging waarop de weergave NPC's en obstakels herbouwt, plus herberekening van het pad in `Loper`; test voor `aanwezig`.
- **M4. Id-labels staan in elke build en op elk object.** `kamer_inhoud.gd:34` (altijd een `Label3D` met het item-id, ook bij een echt model), `kamer_inhoud.gd:209` (NPC), `kamer_vorm.gd:340` en `kamer_bouwer.gd:33` (uitgang toont het ruwe id `deur_hal`). Dat is geen Nederlandse tekst en geen sfeer (pillar 1). Voorstel: labels alleen bij placeholders en alleen als `Ontwikkel.actief()`, en dan met de tekstsleutel `naam`; de speler ziet de naam al bij hover.
- **M5. Schaduwbudget niet gevalideerd, en de logregel uit de spec ontbreekt.** `tools/schemas/room.schema.json` (veld `lichten.schaduw`: "hoogstens 6" staat alleen in de beschrijving, `maxItems` geldt voor alle lichten) en `game/systems/kwaliteit.gd:32-38` (kapt stil af; spec Edge cases vraagt een logregel). Voorstel: validatorregel "meer dan 6 lichten met `schaduw`" met test in `tests/python/test_validator.py`, en een logregel in `KamerLicht.bouw` als het afkapt.
- **M6. Validator mist ruimtelijke fouten die W13/V32 beschrijven.** `tools/onderstad/regels_objecten.py:122-135` controleert alleen grenzen. Niet gecontroleerd: `start_positie` of uitgang op een `geblokkeerd` vak, een uitgang of niet-pakbaar object dat niet bereikbaar is, twee niet-pakbare objecten op één vak. Nu logt pas de weergave "niet beloopbaar" (`kamer_weergave_basis.gd:103`). Voorstel: V32 als echte regel (vloeivulling vanaf `start_positie`) met rode tests.
- **M7. Testgaten voor nieuwe logica.** Geen test voor: hover + pakken (B1), `spel_geladen` (M1), NPC `aanwezig` (M3), `stand` na neerleggen (M2), `Overgang`/`Voorlader` met een echt model, `Meting.schrijf` (KW-16: JSON met alle W24-velden), `StartOpties` met `=`-vorm, `klik_vak` buiten de kamer tijdens lopen, `Kwaliteit.bewaar` bij de eerste-start-meting.
- **M8. CI downloadt een binary zonder controle.** `.github/workflows/ci.yml:46-49`: `curl` van `godot-builds` zonder checksum; de cache bewaart het resultaat daarna onder `godot-4.7.2-stable-...`. Voorstel: `SHA512-SUMS.txt` ophalen en `sha512sum -c` voor het uitpakken; acties vastzetten op een commit-SHA (`checkout@v4`, `setup-python@v5`, `cache@v4`).

## Kan

- `kamer_weergave_basis.gd:189-192`: een klik buiten de kamer of op een onbereikbaar vak wist `_doel` terwijl Richard doorloopt naar het oude doel; de actie vervalt stil. Zet `_doel` pas na de lege-pad-controle.
- `kamer_root.gd:125-137` en `contour.gd:32`: `pik` doet bij elke muisbeweging per pickbaar ding `find_children` en een AABB-berekening. Voor tien objecten prima; bij tientallen modellen cachen.
- `voorlader.gd:30-35`: `klaar()` wacht op alle aangevraagde modellen van alle buurkamers, niet alleen van de bestemming; de overgang blijft langer zwart dan nodig. `aangevraagd` wordt nooit leeggemaakt en `load_threaded_get` wordt nooit aangeroepen. Filter per kamer.
- `main.gd:52` en `Kwaliteit.laad()`: `--meet` zonder `--stand` gebruikt de bewaarde stand in plaats van `vol` (W24). De eerste-start-meting (`main.gd:63-65`) meet vanaf frame 0 en wordt door shader-compilatie naar `licht` getrokken; wacht 1 s en bewaar de keuze pas na bevestiging. In een release-build is er geen F4 om terug te schakelen.
- `main.gd:7,18-21`: de fixture-fallback (pad `tests/fixtures/proef`, `testscene.json`) staat in code; prima voor ontwikkelbuilds, maar leg het pad vast in een ontwikkelinstelling.
- `kwaliteit.gd:13-18`, `kamer_licht.gd:6-47`, `placeholder.gd:4-12`: waarden uit spec en stijlgids staan als constanten in GDScript. Past bij "instellingen per stand als data" (W25) zolang content ze niet stuurt; overweeg `content/instellingen/kwaliteit.json` met schema zodat de art-director ze zonder code bijstelt.
- `kamer_weergave_basis.gd:226-230`: het liftpaneel kiest automatisch de eerste open bestemming; tijdelijk, maar leg het vast als open punt.
- `camera.volgt` (W12) staat in het schema maar wordt genegeerd; log een melding of haal het uit het schema tot het bestaat.
- `camera_stand.gd:54-61`: de bisectie start bij 1 m; bij een zeer kleine FOV of kamer kan `past` door negatieve diepte onterecht slagen. Zet `laag` op `NEAR + diagonaal`.
- Ongetypeerde lusvariabelen (`for p in root.pickbaar`, `for c in kandidaten`, `kamer_raster.gd:18,115`, `contour.gd:10,22,32`). Zet in `project.godot` de waarschuwing `untyped_declaration` aan (al genoemd in `fundament-code.md`).
- `KamerWeergave` is een basis- en afgeleide klasse om onder 300 regels te blijven. Splits liever op verantwoordelijkheid (invoer, hover, close-up, wissel); nu moet je twee bestanden lezen voor één state-machine.
- Lambda-koppelingen aan `Spel`-signalen (`kamer_weergave_basis.gd:52-55`, `kamer_weergave.gd:242`) worden nooit losgekoppeld. Gebruik benoemde methoden en `_exit_tree` zodra de weergave per scène herbouwd wordt.
- `spel.blokkades["closeup"/"droom"]` zijn losse strings (`kamer_weergave_basis.gd:151`, `kamer_weergave.gd:319,342`); definieer constanten naast `blokkades` in `spel_staat.gd`.

## Pillars

| Pillar | Score | Toelichting |
| --- | --- | --- |
| 1. Sfeer is het product | 3/5 | Licht, ambient, vignet, mist, contour en overgang volgen de stijlgids; ruwe id-labels (M4) en kale placeholders drukken het beeld. |
| 2. Een fysieke wereld | 3/5 | Vakken, pad en objecten op vakmiddens kloppen; zwevend object na neerleggen (M2), verouderd raster bij NPC-wissel (M3) en de B1-crash schaden de consistentie. |
| 3. Informatie is de sleutel | 4/5 | Close-up, naam bij hover en spatiebalk ondersteunen het zoeken; liftpaneel is nog een tijdelijke automaat. |
| 4. Twijfel tot het einde | 4/5 | Geen nieuwe verhaalinhoud; de weergave legt geen lezing vast. |

## Oordeel

Eén blokkerend punt (B1), acht "moet". Architectuur (logica los van rendering, statische types in de nieuwe bestanden, 300-regelgrens, content uit JSON, headless testbaar) en de vak-/camerawiskunde zijn goed; er is geen regressie in de bestaande systemen. Niet mergen voordat B1 is opgelost en M1-M3 zijn opgepakt of bewust uitgesteld met een issue.

---

# Ronde 1 (HEAD 56aed43)

Gedraaid: `python tools/test_godot.py` groen (GUT 126/126), `validate.py --all` groen. Diff `d9f67a7..56aed43` gelezen.

| Punt | Opgelost | Opmerking |
| --- | --- | --- |
| B1 hover op gepakt object | Ja | `_objecten_veranderd` wist hover vóór het vrijgeven (`_wis_hover`), plus vangnet in `tik`; `test_b1_hover_op_gepakt_object_geeft_geen_fout` |
| M1 `spel_geladen` | Ja | `_herlaad` bouwt de kamer opnieuw en reset closeup, hover, doel; `test_m1_*` |
| M2 stand na neerleggen | Ja | Plaatsing telt alleen als het object op het beginvak ligt; `test_m2_*` |
| M3 NPC `aanwezig` | Ja | `zet_npcs` elke 0,25 s, raster bijgewerkt, pad herberekend; `test_m3_*` (zie N1) |
| M4 id-labels | Ja | Labels alleen in ontwikkelbuilds, met naam-tekst; uitgangen met `naam` |
| M5 schaduwbudget | Ja | Validatorregel V33 en logregel in `KamerLicht.bouw` |
| M6 ruimtelijke validatie | Ja | V32 in `regels_ruimte.py` (geblokkeerd, dubbele vakken, bereikbaarheid) |
| M7 testgaten | Gedeeltelijk | Nieuw: B1, M1-M3, klik buiten kamer, `Meting`, `Voorlader`. Nog open: `Overgang`/`Voorlader` met echt model, `StartOpties` met `=`-vorm, `Kwaliteit.bewaar` bij eerste start |
| M8 CI-checksum | Gedeeltelijk | `sha512sum -c` toegevoegd; acties staan nog op tag, niet op commit-SHA |

Van de "kan"-punten zijn niet opgepakt (bewust uitgesteld): voorlader-filter per kamer, `--meet` standaard `vol`, constanten naar JSON, `camera.volgt`, ongetypeerde lussen, basis/afgeleide splitsing, lambda-koppelingen.

**Nieuwe blokkerende punten:** geen.

**Nieuw, moet**
- **N1.** `kamer_weergave_basis.gd` (`_npcs_controleren`, `klik_vak`): `_laatste_klik["doel"]` houdt de node van een NPC vast. Verdwijnt precies die NPC terwijl Richard erheen loopt, dan wordt `klik_vak` opnieuw aangeroepen met een vrijgegeven node en `_aangekomen` roept `vak_van` op een vrijgegeven node aan (scriptfout). Voorstel: in `_npcs_controleren` het doel laten vallen als `is_instance_valid(doel["node"])` niet meer klopt, en een test met een NPC die tijdens het lopen verdwijnt.

## Pillars (bijgesteld)

| Pillar | Score |
| --- | --- |
| 1. Sfeer is het product | 4/5 |
| 2. Een fysieke wereld | 4/5 |
| 3. Informatie is de sleutel | 4/5 |
| 4. Twijfel tot het einde | 4/5 |

## Oordeel ronde 1

Niet langer blokkerend. B1 en M1-M6 zijn opgelost, M7-M8 deels; N1 is een randgeval dat vóór het eerste hoofdstuk met bewegende NPC's moet zijn opgelost.
