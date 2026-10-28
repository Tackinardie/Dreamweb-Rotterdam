# QA fundament-3d

Branch iteratie/fundament-3d, fixture tests/fixtures/proef (ch01_proef), testkamer ch01_kantoor. Nog geen echt hoofdstuk.

| # | Check | Uitslag |
| --- | --- | --- |
| 1 | `validate.py --all` | groen (0 fouten; geen spelcontent, alleen cue-catalogus gecontroleerd) |
| 2 | `solve.py ch01_proef --content tests/fixtures/proef` | groen, oplosbaar, 8 stappen, 0 doodlopende staten. Beperking: leg-limiet 1 onmisbaar object buiten beginplek; niet gemodelleerd: stop_in, uitpakken, inventariscapaciteit; limiet niet bereikt (112080 toestanden) |
| 3 | Playthrough | nog niet gebouwd, niet blokkerend voor deze iteratie |
| 4 | `test_godot.py` + pytest | groen: import, rooktest, GUT 119/119; pytest 97 passed |
| 5 | check_windows | nog niet gebouwd, niet blokkerend |
| 6 | check_audio | nog niet gebouwd, niet blokkerend |
| 7 | check_devices | nog niet gebouwd, niet blokkerend |
| 8 | Prestaties | gemeten, zie onder |
| CI | .github/workflows/ci.yml | statisch gelezen, juist: jobs python (validate, pytest, solve) en godot (test_godot.py, Godot 4.7.2 gecachet) op PR en push naar main. Kan pas op GitHub draaien: niet gedraaid. Let op: push naar de iteratiebranch triggert alleen via een PR |

## Prestaties (KW-16)

Machine: NVIDIA GeForce RTX 4080, Vulkan Forward+, venster 1280x720 (niet 1080p), Windows 11. Referentie Iris Xe niet beschikbaar: **niet gemeten op referentie**.

- vol: 239,7 fps gem., 1% laagst 209,7 (doel 60: gehaald op deze machine)
- licht: 239,7 fps gem., 1% laagst 211,1 (doel 30 op Iris Xe: niet gemeten)
- 14 meshes, 4 lichten, 2 met schaduw; JSON bevat alle W24-velden.
- De RTX 4080 is waarschijnlijk begrensd door de CPU/vsync-limiet; de twee standen onderscheiden zich hier niet. Meting op 1080p en op de referentie blijft nodig voor Martijn.

## Acceptatiecriteria

| # | Status |
| --- | --- |
| KW-01 | getest (GUT test_vak_logica, 48 vakken heen en terug) |
| KW-02 | getest (GUT test_kw02) |
| KW-03 | getest (GUT test_kw03) |
| KW-04 | getest (GUT test_kw04) |
| KW-05 | getest (GUT, camera en automatische afstand; zonder Node3D) |
| KW-06 | getest (GUT) |
| KW-07 | getest (GUT, gerandomiseerd) |
| KW-08 | getest (GUT, beide klikgevallen) |
| KW-09 | getest (GUT test_kw09: contouren en logboek); pixels niet testbaar headless |
| KW-10 | getest (GUT: SubViewport, World3D, FOV, geblokkeerd blok); beeld niet testbaar headless |
| KW-11 | getest (GUT test_kw11) |
| KW-12 | getest (GUT: geen laadscherm, duur <= 0,6 s, Richard op deur_kantoor) |
| KW-13 | getest (GUT droomovergang) |
| KW-14 | getest (GUT: standen, terugschakelen, persistentie in testbestand); echte render-effecten niet headless zichtbaar |
| KW-15 | getest (GUT, beide standen) |
| KW-16 | gedeeltelijk: --meet werkt en schrijft alle velden; referentiemeting ontbreekt (niet gemeten op referentie) |
| KW-17 | getest (alle KW in GUT headless; 119/119) |
| KW-18 | getest (pytest: V11 geblokkeerd en licht, dubbel licht-id V01, FOV 40 faalt schema) |

Niet door QA gezien: het daadwerkelijke beeld (sfeer, contour, close-up, fade). Dat vraagt de definition-of-done-stap "Martijn heeft de testkamer gestart en gezien". Er zijn geen rode checks, dus geen issues aangemaakt.

KLAAR VOOR REVIEW
