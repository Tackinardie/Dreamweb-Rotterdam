# Tests

Alle commando's draaien vanaf de repo-root (Windows, Git Bash of PowerShell). Godot 4.7.2 en Python 3.12 staan op het PATH.

## Eenmalig

```
python -m pip install -r tools/requirements.txt
godot --headless --path game --import
```

De tweede regel laat Godot de klassenamen registreren (`.godot/` blijft buiten git). Doe dit ook na het toevoegen van een nieuw script met `class_name`.

## GUT (Godot-systemen), één commando

```
godot --headless --path game -s addons/gut/gut_cmdln.gd -gdir=../tests/gut -gexit
```

- GUT 9.7.1 (bitwes/Gut, tag `v9.7.1`) staat in `game/addons/gut/`.
- `--path game` zet de werkmap op `game/`; daarom is `-gdir` relatief aan `game/`.
- Eén bestand of test draaien: voeg `-gselect=test_objecten` toe (bestandsnaam zonder `.gd`) of `-gunit_test_name=test_oi04`.
- Exitcode 0 = alles groen. Elke test noemt zijn acceptatiecriterium (OI-, TG-, SF-, KS-, AC-nummer) in de naam of de assertie.

| Bestand | Dekt |
| --- | --- |
| `gut/test_objecten.gd` | OI-01 t/m OI-12 |
| `gut/test_toegang.gd` | TG-01 t/m TG-09, TG-11 |
| `gut/test_condities.gd` | SF-01 t/m SF-07 |
| `gut/test_state.gd` | SF-08 t/m SF-16, doel bereiken, gesprekken |
| `gut/test_klok.gd` | KS-01 t/m KS-05, KS-07 t/m KS-10 |
| `gut/test_audio.gd` | AC-03 t/m AC-10 |
| `gut/test_project.gd` | geen hardcoded content, scripts < 300 regels, autoloads, lege hoofdscene |

`gut/hulp.gd` laadt de fixture en bouwt een `Spel`; de tests staan buiten `res://` en laden hem met `preload("hulp.gd")`.

## Python (validator en oplosser)

```
python -m pytest tests/python -q
```

Duurt ongeveer een minuut: de oplosser doorzoekt een paar duizend tot ruim honderdduizend toestanden.

| Bestand | Dekt |
| --- | --- |
| `python/test_condities.py` | SF-01 (dezelfde `condities.json` als GUT), SF-06, SF-07 |
| `python/test_validator.py` | fixture groen, lege content groen, 23 kapotte varianten, AC-01, AC-02, AC-03, TG-10, OI-13, KS-05, KS-06, KS-11, SF-17 |
| `python/test_oplosser.py` | SF-18 |

## Validator en oplosser met de hand

```
python tools/validate.py --all
python tools/validate.py --content tests/fixtures/proef --cues tests/fixtures/proef/cues.json
python tools/validate.py --content tests/fixtures/proef --overlay tests/fixtures/kapot/geen_tegenstuk --cues tests/fixtures/proef/cues.json
python tools/solve.py ch01_proef --content tests/fixtures/proef
python tools/solve.py ch01_proef --content tests/fixtures/proef --overlay tests/fixtures/kapot/doodlopend_rapport_weg
```

`--overlay` legt een kapotte variant over de fixture heen (bestanden met hetzelfde relatieve pad vervangen het origineel).
`solve.py` heeft `--leg-limiet N` (standaard 1): hoeveel onmisbare objecten tegelijk buiten hun beginplek mogen liggen. Hoger is grondiger en exponentieel trager.

## Fixtures (`tests/fixtures/`)

- `proef/`: een klein fictief hoofdstuk (`ch01_proef`, drie kamers, vijftien objecten met geneste containers, een pas, een deur met `vereist`, een lift, een code-token, een gebeurtenis met routine, een NPC met twee gesprekken, een laptop, een puzzelgraaf van elf knopen) met eigen tekst en cue-catalogus. Geen echte Onderstad-content.
- `condities.json`: de gedeelde testset van de conditietaal (SF-01), gelezen door GUT en Python.
- `kapot/<naam>/`: opzettelijk kapotte varianten als overlay. Ze worden gegenereerd door `python tests/fixtures/maak_kapot.py`; `test_varianten_zijn_actueel` bewaakt dat ze overeenkomen met dat script. Pas varianten dus aan in het script, niet met de hand.
