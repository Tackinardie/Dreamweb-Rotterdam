#!/usr/bin/env bash
# Eenmalige inrichting van de tracker op GitHub: labels, milestones, projectbord en de startissues.
# Gebruik: tools/setup_github.sh   (vanuit de root van de repo, met `gh auth login` gedaan)
set -euo pipefail

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
OWNER=${REPO%%/*}
echo "Inrichten van $REPO"

label() { gh label create "$1" --color "$2" --description "$3" --force >/dev/null; }

# Type
label "type:taak"      "1f6feb" "Een stuk werk"
label "type:bug"       "d73a4a" "Iets werkt niet volgens GDD of spec"
label "type:wijziging" "a371f7" "Ontwerpwijziging die moet doorwerken"
# Status (naast de kolommen op het bord; agents zetten deze via gh)
label "status:geblokkeerd" "b60205" "Wacht op een beslissing of ander werk"
label "status:martijn"     "fbca04" "Wacht op een keuze of actie van Martijn"
# Hoofdstukken
for c in "ch00:Hub" "ch01:Katendrecht" "ch02:Woontoren" "ch03:Markthal-Centraal" "ch04:Maasvlakte" "ch05:Erasmus-MC" "ch06:Delfshaven" "ch07:Vliegveld"; do
  label "hoofdstuk:${c%%:*}" "0e8a16" "${c#*:}"
done
label "hoofdstuk:systeem" "0e8a16" "Hoofdstukoverstijgend systeem"
# Agents
for a in producer verhaalarchitect locatie-onderzoeker systems-designer level-designer puzzle-designer schrijver \
         godot-engineer asset-pipeline geluidsontwerper qa-tester lore-keeper art-director playtest-criticus code-reviewer martijn; do
  label "agent:$a" "5a6270" "Eigenaar: $a"
done

# Milestones = fases uit de roadmap
ms() { gh api "repos/$REPO/milestones" -f title="$1" -f description="$2" >/dev/null 2>&1 || true; }
ms "Fase 0 · Fundament"       "Repo, schema's, agents, kernsystemen, validator en oplosser"
ms "Fase 1 · Vertical slice"   "Hub + hoofdstuk 1 Katendrecht, telefoon-puzzel, eerste droom"
ms "Fase 2 · Hoofdstukken 2–4" "Woontoren, Markthal/Centraal, Maasvlakte; hintsysteem"
ms "Fase 3 · Hoofdstukken 5–7" "Erasmus MC, Delfshaven, vliegveld; het einde"
ms "Fase 4 · Afronding"        "Art, audio, externe testers, release-build"

# Projectbord (GitHub Projects)
PROJECT=$(gh project list --owner "$OWNER" --format json -q '.projects[] | select(.title=="Onderstad") | .number' || true)
if [ -z "$PROJECT" ]; then
  PROJECT=$(gh project create --owner "$OWNER" --title "Onderstad" --format json -q .number)
  gh project link "$PROJECT" --owner "$OWNER" --repo "$REPO" || true
fi
echo "Projectbord: #$PROJECT"

issue() { # titel, milestone, labels, body
  local url
  url=$(gh issue create --title "$1" --milestone "$2" --label "$3" --body "$4")
  gh project item-add "$PROJECT" --owner "$OWNER" --url "$url" >/dev/null
  echo "  $url"
}

F0="Fase 0 · Fundament"; F1="Fase 1 · Vertical slice"
issue "JSON-schema's voor item, room, puzzle, dialogue, device, chapter" "$F0" "type:taak,agent:systems-designer,hoofdstuk:systeem" "Schema's in tools/schemas/. Zie GDD > Technische architectuur."
issue "Specificaties kernsystemen: objecten/inventaris, toegang, state, klok, audio-cues" "$F0" "type:taak,agent:systems-designer,hoofdstuk:systeem" "Per systeem docs/systemen/<systeem>.md volgens de systems-designer."
issue "Godot 4-project met autoloads GameState en Content, plus GUT" "$F0" "type:taak,agent:godot-engineer,hoofdstuk:systeem" "Lege maar draaiende basis met tests."
issue "tools/validate.py en tools/solve.py" "$F0" "type:taak,agent:godot-engineer,hoofdstuk:systeem" "Validator tegen de schema's en oplosser voor de puzzelgraaf."
issue "Stijlgids v0" "$F0" "type:taak,agent:art-director,hoofdstuk:systeem" "Op basis van de visuele referenties van Martijn."
issue "Startpakket: personageblad doelwit 1 en bijfiguren" "$F0" "type:taak,agent:martijn,status:martijn,hoofdstuk:ch01" "Samen met de verhaalarchitect."
issue "Startpakket: stemvoorbeeld (één pagina)" "$F0" "type:taak,agent:martijn,status:martijn,hoofdstuk:systeem" "Eigen dialoog en objectbeschrijvingen."
issue "Startpakket: 5 à 10 visuele referenties" "$F0" "type:taak,agent:martijn,status:martijn,hoofdstuk:systeem" "Games, Rotterdam bij nacht, palet."
issue "Startpakket: fictief merkenuniversum" "$F0" "type:taak,agent:martijn,status:martijn,hoofdstuk:systeem" "Bezorgapp, vervoerder, snackbarketen, energiedrank, branding Het Hart."
issue "Hoofdstuk 1 Katendrecht: vertical slice" "$F1" "type:taak,agent:producer,hoofdstuk:ch01" "Zie GDD > Vertical slice. Start met /iteratie ch01."

echo
echo "Klaar. Zet nog eenmalig in het bord (Settings > Workflows) 'Auto-add to project' aan voor deze repo,"
echo "en zet in de repo Settings > Pages de bron op 'GitHub Actions'."
