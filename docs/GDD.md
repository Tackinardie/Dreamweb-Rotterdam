# Onderstad — Game Design Document

27 oktober 2026 · Martijn Tack

> Bron: het Game Design Document in Claude. Wijzigingen in dit bestand openen automatisch een ontwerpwijzigings-issue.

## Pitch

**Onderstad** is een donkere, top-down point-and-click adventure in hedendaags Rotterdam, geïnspireerd door DreamWeb (1994). Rotterdam is de stad zonder hart, en zeven mensen bouwen er nu één: **Het Hart**, een stadsproject waar alle data van de stad naartoe vloeit. Wie Het Hart bezit, heeft absolute macht. Jij speelt een flitsbezorger die in zijn dromen ziet wat er gebeurt als het gaat kloppen, en besluit de zeven te stoppen voordat het zover is. Of is dat alleen waar in zijn hoofd?

| Kenmerk | Keuze |
| --- | --- |
| Werktitel | Onderstad |
| Genre | Narratieve adventure, top-down, puzzels |
| Perspectief | Low-poly 3D met vlakke kleuren en sterk realtime licht; vaste schuine camera van bovenaf |
| Setting | Rotterdam, nu; plus een droomwereld: het vooroorlogse Rotterdam |
| Speelduur | 4 à 6 uur (7 hoofdstukken + hub) |
| Engine | Godot 4 |
| Platform | PC (Windows eerst); demo alleen als download, geen webversie |
| Taal | Nederlands, met Rotterdamse directheid |
| Inspiratie | DreamWeb, Her Story, Hacknet, Disco Elysium (toon) |

De kernervaring: **'s nachts door een natte stad bewegen, overal binnenkomen omdat niemand een bezorger ziet, en informatie als sleutel gebruiken.**

## Design pillars

Vier pillars bepalen elke ontwerpbeslissing. Een feature die geen pillar versterkt, gaat eruit.

1. **Sfeer is het product.** Regen, neon, nat asfalt, stilte. Elke ruimte vertelt iets zonder tekst. Toets: voelt een scherm zonder UI al als Onderstad?
2. **Een fysieke wereld.** Objecten bestaan echt: je pakt ze op, legt ze neer, stopt ze in iets anders. Puzzels volgen alledaagse logica, geen absurde combinaties. Toets: zou een echt mens dit zo oplossen?
3. **Informatie is de sleutel.** Telefoons, panelen, mails, socials en dienstroosters geven toegang. De speler leest en leidt af. Toets: lost de speler het op met zijn hoofd, niet met trial-and-error?
4. **Twijfel tot het einde.** Uitverkorene, pion of psychoot? Elk hoofdstuk voedt beide lezingen. Toets: kan dit moment op twee manieren gelezen worden?

**Anti-pillars** (bewust niet): geen gevechtssysteem, geen skilltrees, geen open wereld, geen humor als toon, geen game-over door doodgaan, geen geldsysteem (geen saldo, niets kopen of verkopen; een ov-kaart of pas is gewoon een object), geen overlevingsbehoeften (geen meters voor honger, dorst of vermoeidheid; slapen gebeurt alleen als verhaalmoment, voor de dromen; eten en drinken komen alleen voor als een puzzel of het verhaal er logisch om vraagt, zoals koffie voor de nachtportier).

## Setting en thema

Het thema is **de stad zonder hart**: Rotterdam verloor op 14 mei 1940 zijn oude centrum en bouwde zich opnieuw op. Zadkines *De Verwoeste Stad*, een figuur met een gat waar het hart zit, is het centrale beeld van de game. Martijn heeft akkoord om het beeld en het Markthal-plafond te gebruiken; leg dat schriftelijk vast in docs/rechten.md.

**Het Hart.** De stad zonder hart krijgt een nieuw middelpunt: een toren aan de Maas met daaronder een netwerk dat alles koppelt. Camera's, verkeer, haven, energie, zorgdata, bezorgapps, socials: alle data van Rotterdam vloeit ernaartoe. Officieel heet het efficiëntie en veiligheid. In werkelijkheid geeft het de zeven mensen die het bouwen absolute macht over de stad: zij zien alles, sturen alles en kunnen iedereen raken. Het Hart gaat aan het einde van de game live; de speler heeft zeven nachten.

**De kernvraag** is niet of de hoofdpersoon het mag tegenhouden, maar wat hij daarvoor bereid is te doen, en of zijn beeld van de dreiging klopt.

**Twee lagen**

- **De bovenstad**: Rotterdam nu. Torens, haven, gentrificatie, camera's, bezorgapps, eenzaamheid in een volle stad. Altijd nacht of schemer, bijna altijd regen.
- **De onderstad**: het verdwenen vooroorlogse Rotterdam, stil, monochroom en verwrongen. Daar krijgt de hoofdpersoon zijn opdrachten. Het verandert per hoofdstuk, alsof het beschadigd raakt of juist herstelt.

**Het web, dubbel gelezen**

- Mystiek: de onderstad, waar de dromen hem tonen wat Het Hart met de stad gaat doen.
- Modern: het netwerk van Het Hart zelf, dat elke nacht verder groeit. De bezorgorders die hem naar de doelwitten sturen komen ook uit dat netwerk. Wie stuurt ze?

**Toon**: melancholisch, sober, volwassen. Geweld is kort, hard en zonder spektakel. Tijdens het verkennen is er weinig dialoog; op sleutelmomenten volgen lange, gespannen gesprekken (zie Regiestijl).

**Tijd**: de game begint op zaterdag 1 januari 2022, net na middernacht, en loopt tot de ochtend van vrijdag 7 januari 2022. Nederland zit in de lockdown van december 2021: horeca, winkels en musea zijn dicht, er geldt een vuurwerkverbod (er wordt toch geknald), mensen mogen weinig bezoek ontvangen. De stad is 's nachts leeg, op bezorgers na; flitsbezorgers zijn drukker dan ooit. Flitsbezorgers bezorgen tot ongeveer 23:00, dus orders komen 's avonds binnen; wat daarna gebeurt, gebeurt in een lege stad. Achter gesloten deuren gaat het leven door: kleine huisfeestjes (op oudejaarsavond mochten vier gasten komen) en hier en daar een illegale bar, alleen voor genodigden. Elk hoofdstuk toetst de locatie aan de maatregelen van die week. Het jaartal wordt niet nadrukkelijk getoond, maar alles in de wereld (data in berichten, de krant, de maatregelen) moet ermee kloppen.

**Realiteit en fictie**: Rotterdam is herkenbaar, maar alle personages en organisaties zijn fictief. Echte instellingen krijgen een gefictionaliseerde naam (zie Hoofdstukstructuur).

## Regiestijl: Tarantino als aanpak

Verhaal en omgeving worden geregisseerd in de manier van werken van Quentin Tarantino: niet zijn verhalen, personages of scènes, maar zijn technieken om spanning, ritme en personage op te bouwen. Deze sectie is bindend voor de verhaalarchitect, de locatie-onderzoeker, de level-designer en de schrijver, en wordt getoetst door de lore-keeper en de playtest-criticus.

| Techniek | Wat het betekent in Onderstad |
| --- | --- |
| Hoofdstukken met titelkaart | Elk hoofdstuk opent met een titelkaart, bijvoorbeeld "Hoofdstuk 3: De Markthal". De nachten voelen als losse verhalen die samen één geheel vormen. |
| De bom onder de tafel | De speler weet meer dan de personages in het gesprek: dat de beveiliger terugkomt, dat het doelwit hem herkent, dat de telefoon in zijn zak zo gaat trillen. De spanning zit in wat niet gezegd wordt. |
| Praten over niets | Sleutelgesprekken beginnen alledaags: eten, voetbal, de snackbar, het weer, de bezorgapp. Personages worden getekend door hoe ze praten, niet door wat ze uitleggen. Pas daarna kantelt het gesprek. |
| Lange opbouw, korte ontlading | Confrontaties bouwen langzaam op via dialoog en kleine handelingen. De ontlading is kort en abrupt. Daarna is het stil. |
| Niet-lineair vertellen | Maximaal twee keer in de game een tijdsprong of perspectiefwissel: een korte scène als een doelwit, uren eerder, of dezelfde gebeurtenis gezien door een ander. Zo valt pas later op zijn plek wat de speler eerder zag. |
| Standoffs | Op een paar momenten staan drie partijen tegenover elkaar, elk met iets wat de ander wil. Wie beweegt eerst? Opgelost via dialoogkeuzes en timing, niet via vechten. |
| Personage-introducties | Bij de eerste verschijning van elk doelwit bevriest het beeld kort met een naamkaart en één veelzeggend detail. |
| Een eigen merkenuniversum | Fictieve merken keren door de hele game terug: een snackbarketen, een energiedrank, een sigarettenmerk, de bezorgapp. Ze maken de wereld consistent en herkenbaar zonder echte merken. |
| Muziek als regie | Muziek klinkt vaak uit de wereld zelf (een radio, een telefoon, de bar) en botst bewust met de scène: iets vrolijks op het meest gespannen moment. |
| Inzoomen op details | Het top-down beeld blijft, maar in sleutelmomenten verschijnen close-up panelen: handen, een glas, een scherm, ogen. |

**Grenzen**

- Geen overname van scènes, dialogen, personages of herkenbare beelden uit zijn films. Alleen de technieken.
- Geweld blijft kort en zonder spektakel (zie Toon). De Tarantino-aanpak gaat over de opbouw, niet over het tonen van geweld.
- Droge, alledaagse humor in gesprekken mag; humor als toon van de game blijft een anti-pillar.
- De niet-lineaire momenten mogen de speler nooit doen verdwalen in de gameplay: ze zijn kort en duidelijk gemarkeerd.

## Verhaal en personages

Het verhaal volgt zeven nachten en zeven doelwitten voordat Het Hart live gaat, en eindigt bij zonsopgang op het vliegveld.

**Verhaalskelet**

1. **Opzet**: de jaarwisseling. Hij zit alleen op zijn studentenkamer; buiten knalt illegaal vuurwerk boven de daken. Student met een bijbaan als flitsbezorger, slaapt slecht. In een droom ziet hij Rotterdam waarin Het Hart klopt: stille straten, iedereen gestuurd, niemand die nog nee zegt. Een gestalte zonder hart geeft hem een naam.
2. **Eerste nacht**: een bezorgorder naar precies die naam: de projectontwikkelaar. In zijn loft ziet hij voor het eerst de plannen van Het Hart.
3. **Escalatie**: elke nacht een nieuwe order, een nieuw doelwit, een nieuw stuk van het netwerk (wie, hoe, wanneer het live gaat). Het Hart groeit intussen: camera's, de app en de mensen om hem heen lijken hem steeds beter te zien.
4. **Kantelpunt (Erasmus MC-level)**: de slaaponderzoeker levert de technologie die mensen aan Het Hart koppelt. Hij vindt zijn eigen dossier: hij wist dat hij proefpersoon was, maar niet waarvoor.
5. **Persoonlijk (Delfshaven)**: het zesde doelwit is iemand uit zijn eigen verleden die ook aan Het Hart meewerkt.
6. **Finale (vliegveld)**: Het Hart gaat bij zonsopgang live. Het laatste doelwit, de bestuurder, vlucht met de eerste privévlucht.

**Openingsscène: de jaarwisseling**

Het spel begint net na middernacht in de nieuwjaarsnacht. De hoofdpersoon is alleen op zijn studentenkamer. Door het raam zie je losse illegale vuurpijlen boven de daken, met de Erasmusbrug als verlichte lijn in de verte; je hoort knallen in lege straten, de buren houden een klein feestje achter de muur, zijn telefoon blijft stil.

- **Contrast**: de hele stad viert samen, hij is alleen. Dat is de toon van de game in één beeld.
- **Echo van 1940**: de flitsen en knallen van het vuurwerk gaan langzaam over in het bombardement. Zo begint de eerste droom: het vuurwerk wordt de brand van de oude stad, en daarna toont de onderstad wat Het Hart gaat doen.
- **Eerste interactie**: de speler kan de kamer verkennen (bureau, studieboeken, bezorgtas, een ongeopend bericht van thuis: kort, "bel even, het is belangrijk"; wat er speelt is nog open) voordat de droom begint. Zo leert de speler bewegen en bekijken zonder tutorial.
- **Tijdlijn**: de zeven nachten lopen van nieuwjaarsnacht tot de zevende ochtend van januari. Het Hart gaat live bij zonsopgang op die ochtend, gepresenteerd als het nieuwe begin van de stad.

**Waan of waarheid?** Of de dreiging van Het Hart echt is, ligt nog open (zie Open vragen). Tot die keuze valt, schrijven alle agents zo dat beide lezingen kloppen: elk bewijs heeft een tweede, onschuldige verklaring.

**Personages**

| Rol | Wie | Functie in het verhaal |
| --- | --- | --- |
| Hoofdpersoon | 22, studeert data/informatica aan de universiteit, bijbaan als flitsbezorger; zijn vriendengroep ging verder (afgestudeerd, verhuisd, relaties) en hij bleef achter; deed vorige zomer mee aan een betaald slaaponderzoek en weet niet meer precies wat daar gebeurde. Naam: Richard (een knipoog naar Ryan uit DreamWeb); zijn achternaam wordt nooit genoemd | Onzichtbaar, overal toegang, onbetrouwbare verteller; wil Het Hart stoppen |
| De gestalte | Figuur met een gat in de borst, in de onderstad | Toont hem wat Het Hart gaat doen; waarschuwing of waan |
| De app | Bezorgplatform op zijn telefoon | Stuurt hem naar de doelwitten; onduidelijk wie erachter zit |
| Het Hart | Stadsproject: toren aan de Maas + datanetwerk | De dreiging; groeit elke nacht |
| Buurvrouw | Oudere Rotterdamse in de hub | Anker in de realiteit, kent hem van vroeger |
| Barman | Witte de Withstraat; zijn bar is dicht door de lockdown, hij woont erboven en klust 's avonds alleen in de zaak | Informatiebron, geruchten, roddel; laat Richard via de zijdeur binnen |
| Zeven doelwitten | De bouwers van Het Hart (zie hieronder) | Samen één netwerk; elk hoofdstuk legt een stuk bloot |

**De zeven bouwers van Het Hart**

| # | Doelwit | Rol in Het Hart | Wat de speler ontdekt |
| --- | --- | --- | --- |
| 1 | Projectontwikkelaar | Bouwt de toren, het fysieke hart | De plannen en de deadline |
| 2 | Data/beveiligingsondernemer | Bouwt het netwerk | Welke data erin gaat |
| 3 | Influencer | Verkoopt Het Hart aan de stad | Hoe de publieke opinie gestuurd wordt |
| 4 | Havenlogistiek-baron | Financiert het | Wie er echt achter het geld zit |
| 5 | Slaap/neuro-onderzoeker | Koppelt mensen aan het netwerk | Zijn eigen dossier |
| 6 | Persoonlijk doelwit | Iemand uit zijn verleden, werkt mee | Waarom juist hij gekozen werd |
| 7 | Bestuurder | Geeft vergunning en dekking; vlucht | Het moment waarop Het Hart live gaat |

**Zeven confrontaties, zeven manieren**

Elk doelwit sterft op een andere manier. De manier hoort bij zijn rol in Het Hart (het werk keert zich tegen de maker), gebruikt een ander spelsysteem, en heeft altijd een tweede, onschuldige verklaring. Over de zeven nachten komt de hoofdpersoon steeds dichterbij: van op afstand via de omgeving naar oog in oog.

| # | Doelwit | Manier | Spelsysteem | Regie | Tweede lezing |
| --- | --- | --- | --- | --- | --- |
| 1 | Projectontwikkelaar | **Zijn eigen bouwwerk**: een ongeluk op hoogte op zijn bouwplaats, dat de speler in de omgeving in gang zet | Omgeving en objecten, kleding (bouwhelm, hesje) | Lange opbouw, hij praat over zijn toren; dan stilte | Bedrijfsongeval op een bouwplaats |
| 2 | Data/beveiligingsondernemer | **Zijn eigen systeem**: zijn beveiligde ruimte sluit hem op en de systemen doen de rest | Telefoon en smart home, apparaten | De bom onder de tafel: jij weet wat er gaat gebeuren, hij niet | Een storing in zijn eigen beveiliging |
| 3 | Influencer | **In het openbaar, ongezien**: midden in de menigte, tijdens een livestream, wordt ze onwel | Kleding en rol (cateraar), timing, camera's | Muziek uit de wereld botst met het moment; het gebeurt live | Onwel geworden tijdens een evenement |
| 4 | Havenlogistiek-baron | **Zijn eigen machines**: de geautomatiseerde haven volgt een planning die de speler heeft omgeleid | Apparaten en toegang op afstand | Een lege, enorme ruimte; geen mens te zien | Een technische fout in de automatisering |
| 5 | Slaap/neuro-onderzoeker | **In de droom**: de confrontatie gebeurt in de onderstad, terwijl hij in zijn eigen slaaplab ligt; hij wordt niet meer wakker | Droomsysteem | Niet-lineair: dezelfde nacht, twee keer verteld | Overleden in zijn slaap tijdens een eigen experiment |
| 6 | Persoonlijk doelwit | **Met eigen handen**: oog in oog, aan het water in Delfshaven; de enige die de hoofdpersoon kende | Dialoog, geen hulpmiddelen | Langste gesprek van de game; standoff; zeer korte ontlading | 's Nachts in het ijskoude water gevallen |
| 7 | Bestuurder | **Een keuze bij zonsopgang**: een standoff op het platform tussen bestuurder, beveiliging en hoofdpersoon; hoe het afloopt, bepaalt de speler | Kleding (crew), timing, dialoogkeuzes | Standoff met drie partijen; het licht van de zonsopgang | Hangt af van de keuze; voedt het open einde |

**Regels**

- **Nooit twee keer hetzelfde**: geen manier, geen spelsysteem als hoofdmiddel en geen locatie-element wordt herhaald. De lore-keeper bewaakt dit.
- **Buiten beeld en zonder uitvoeringsdetails**: de game toont de opbouw en de gevolgen, niet de handeling zelf. Er komen geen realistische, na te volgen werkwijzen in beeld, tekst of puzzels; de puzzel draait om toegang, timing en informatie, niet om technische details van het doden.
- **Altijd twee lezingen**: na elke confrontatie meldt het nieuws (tv, telefoon, perronreclame) de onschuldige verklaring. De speler blijft twijfelen of hij het zelf deed.
- **Geen game-over**: mislukken kost tijd of een andere route, nooit een herstart.

**Regel voor de doelwitten**: elk doelwit is fictief, heeft een menselijke kant die de speler in de omgeving vindt, en een overtuiging dat Het Hart de stad beter maakt. Geen doelwit is puur kwaadaardig.

**Personages actief ontwikkelen** (met de verhaalarchitect)

1. **Interviewsessies**: per personage stelt de verhaalarchitect vragen met opties; jij kiest. Het personageblad groeit alleen uit jouw keuzes.
2. **Het personage interviewen**: Claude speelt het personage in de eerste persoon en jij stelt vragen. Wat de stem raakt, gaat het blad in.
3. **Scènetests**: de schrijver maakt één korte scène met het personage. Klopt het niet, dan pas je het blad aan, niet de scène.
4. **Waarheidsdocument**: jij schrijft wat er echt gebeurd is (wie stuurt de orders, was hij patiënt, wat is de gestalte). Agents lezen het; de speler ziet het nooit direct.
5. **Vindbaar maken**: per personage leg je vast wat de speler in de omgeving vindt (foto, bericht, object).

**Sjabloon personageblad** (`docs/personages/<naam>.md`)

| Veld | Inhoud |
| --- | --- |
| Wil | Wat hij bewust nastreeft |
| Nodig | Wat hij eigenlijk nodig heeft |
| Wond | Wat hem gevormd heeft |
| Geheim | Wat niemand weet, ook de speler niet direct |
| Relatie tot de stad | Welk stuk Rotterdam bij hem hoort en waarom |
| Stem | Drie voorbeeldzinnen |
| Vindbaar | Wat de speler over hem ontdekt, en waar |
| Twee lezingen | Hoe hij past in "uitverkoren" én in "waan" |

## Hoofdstukstructuur en levels

De game heeft een hub en zeven hoofdstukken. Elk hoofdstuk heeft één locatie, één doelwit, één nieuw mechanisme en eindigt met een droom.

| # | Locatie (in-game naam) | Doelwit (archetype) | Nieuw mechanisme | Kernpuzzel |
| --- | --- | --- | --- | --- |
| 0 | Witte de Withstraat / Kop van Zuid (hub) | — | Bewegen, objecten, bezorgapp | Eerste order aannemen |
| 1 | Katendrecht | Projectontwikkelaar | Gevonden telefoon kraken | Toegang tot een verbouwd pakhuis |
| 2 | Woontoren aan de Maas | Data/beveiligingsondernemer | Liften en toegangsniveaus | Van lobby naar penthouse |
| 3 | Markthal / Centraal | Influencer | Camera's en menigte | Ongezien blijven, socials als bron |
| 4 | Maasvlakte | Havenlogistiek-baron | Geautomatiseerde systemen | Robots en containerplanning omleiden |
| 5 | Maasstad Medisch Centrum (Erasmus MC) | Slaap/neuro-onderzoeker | Roosters en personeelspassen | Nachtdienst, slaaplab, dakplatform |
| 6 | Delfshaven | Persoonlijk doelwit | Herinneringen als aanwijzingen | De poort naar de onderstad |
| 7 | Rotterdam Airport Zestienhoven | Bestuurder | Zonsopgang als vast eindpunt | Landside naar airside naar de hangar |

**Opbouw van een hoofdstuk** (sjabloon voor elke level)

1. **Order**: de app stuurt een adres.
2. **Verkennen**: de buitenkant, de mensen, wat er ligt.
3. **Toegang**: 2 à 4 puzzels die elkaar voeden (object, informatie, timing).
4. **Binnen**: de persoonlijke ruimte van het doelwit; de menselijke kant vinden.
5. **Confrontatie**: kort en hard, zonder vechtsysteem.
6. **Droom**: de onderstad verandert; nieuw stukje van het grotere verhaal.

**Erasmus MC-level**: nachtdienst met lege gangen en tl-licht. Je komt binnen als bezorger bij de avondploeg. Puzzels: personeelspassen, dienstroosters, een vergeten ingelogde werkplek, liften met beperkte toegang. Climax op het helikopterplatform. Hier vindt de speler een dossier met de naam van de hoofdpersoon en wordt de onderstad tastbaar via het slaaplab.

**Vliegveld-level**: het vliegveld is 's nachts dicht; het doelwit vertrekt met de eerste privévlucht. Lege terminal, beveiligingsstraat, airside-grens, hangar met businessjet, platform in de regen. Toegang via crewbadge of cateringlevering. Eindigt bij zonsopgang op de baan.

## Core loop en kernmechanieken

De speler brengt het grootste deel van de tijd door in de stap *toegang regelen*: daar zitten de puzzels.

```
Order via de app → Verkennen → Toegang regelen → Binnen bij het doelwit → Confrontatie → Droom: de onderstad → (volgende order)
```

De lus herhaalt zich per hoofdstuk; de hub ligt tussen elke droom en de volgende order.

**Kernmechanieken**

| Mechaniek | Wat de speler doet | Pillar |
| --- | --- | --- |
| Klik-om-te-lopen | Bewegen door top-down ruimtes | Sfeer |
| Bekijken / gebruiken / pakken | Interactie met objecten en mensen | Fysieke wereld |
| Inventaris met containers | Beperkte slots; tas, jas, portemonnee als containers | Fysieke wereld |
| Telefoon-interface | Gevonden telefoons, panelen, mails, socials doorzoeken | Informatie |
| Notitieboek | Gevonden feiten (namen, codes, tijden) worden automatisch genoteerd en zijn combineerbaar | Informatie |
| Onzichtbaarheid | Met bezorgtas en jas kom je binnen; zonder val je op | Fysieke wereld |
| Gesprekken | Korte, keuze-arme dialogen; informatie halen, niet onderhandelen | Sfeer |
| Droomovergang | Na elke confrontatie; de onderstad verandert | Twijfel |

**Geen game-over.** Fouten kosten tijd of een omweg, nooit een herstart. Doodlopende situaties (een onmisbaar object kwijt) zijn uitgesloten door ontwerp en door automatische tests.

## Systemen

Tien systemen dragen de game. Alle content staat in data (JSON of Godot-resources), zodat agents levels kunnen maken zonder code aan te passen. Hieronder staan de uitgangspunten; de uitgewerkte specificaties beheert de systems-designer in docs/systemen/.

**1. Objectsysteem**

- Elk object heeft: `id`, `naam`, `beschrijving`, `grootte` (1–3 slots), `pakbaar`, `container` (ja/nee, capaciteit, maximale grootte van wat erin past), `acties` (bekijk, gebruik, open, lees, pak).
- Objecten vormen een boom: kamer → kast → jas → portemonnee → pasje. Elk object bestaat één keer en ligt altijd op één plek.
- Neergelegde objecten blijven waar ze liggen, per locatie opgeslagen.
- Inventaris: 8 slots; containers die je draagt tellen als extra ruimte.

**2. Telefoon- en informatiesysteem**

- Apparaten (telefoon, deurpaneel, werkplek, liftpaneel) zijn schermen met apps: berichten, mail, foto's, socials, notities, agenda.
- Vergrendeling: pincode, patroon of wachtwoord, af te leiden uit de wereld (verjaardag op een taart, hondennaam op een etensbak, kenteken op een foto).
- Gevonden feiten gaan naar het **notitieboek** als *feit-tokens* (bijv. `pin_ontwikkelaar=0412`). Puzzels vragen om tokens, niet om exacte invoer van de speler, om frustratie te voorkomen.

**3. Toegangssysteem**

- Deuren, liften, poorten en slagbomen hebben een `vereist`-regel: object, token, flag, tijd of combinatie. Een deur heeft per kant een eigen regel. Tijd betekent kloktijd, scènetijd of een scènegebeurtenis (zoals de pauze van de beveiliger), niet lopende minuten.
- Toegang, puzzelgraaf en dialoog gebruiken één gedeelde conditietaal (zie docs/systemen/state-en-flags.md); toestand verandert alleen via de puzzelgraaf.
- Toegangsniveaus per gebouw (lobby, verdieping, dak, airside).
- Onzichtbaarheid: met bezorgtas zichtbaar als bezorger; NPC's reageren daarop.

**4. State en flags**

- Globale flags (`hoofdstuk`, `dossier_gevonden`) en lokale flags per locatie.
- Elke puzzel is een knoop in een **afhankelijkheidsgraaf** (wat moet je hebben/weten om dit te doen). Die graaf is de bron van waarheid voor ontwerp, hints en automatische oplosbaarheidstests.
- Opslaan: automatisch bij elke kamerwissel; één handmatig slot.

**5. Droomsysteem**

- De onderstad is één kaart met lagen die per hoofdstuk aan- of uitgaan (gebouwen die terugkomen of verdwijnen).
- Overgangen: visueel filter (desaturatie, ruis), audio-omslag, geen laadscherm.

**6. Voetsporen- en vochtsysteem**

Waar je loopt, laat je sporen achter. Buiten worden je schoenen nat en vies; binnen zie je je eigen voetstappen op de vloer, die langzaam opdrogen en verdwijnen.

- **Schoenstatus**: twee waarden van 0 tot 1, *nat* en *vuil*. Buiten in de regen stijgt *nat*; door plassen en over de bouwplaats stijgen beide sterk.
- **Drogen binnen**: binnen daalt *nat* geleidelijk (richtwaarde: van 1 naar 0 in 2 à 3 minuten speeltijd). *Vuil* slijt per stap langzamer af. Een deurmat of droogloopmat haalt beide in een paar stappen flink omlaag.
- **Afdrukken**: elke stap op een binnenvloer stempelt een afdruk (links/rechts, in looprichting). De zichtbaarheid hangt af van *nat* en *vuil* op dat moment.
- **Verdwijnen**: natte afdrukken drogen op en vervagen in ongeveer een minuut; vuil vervaagt trager en blijft als lichte veeg nog een tijd zichtbaar. Per vloermateriaal verschilt het: tegels en linoleum tonen alles, tapijt absorbeert en toont vooral vuil, beton toont nauwelijks iets.
- **Persistentie**: afdrukken worden per kamer bewaard met een tijdstempel. Kom je terug, dan berekent het spel hoeveel er inmiddels is opgedroogd.
- **Ook NPC's** die van buiten komen laten afdrukken achter.
- **Gameplay**: afdrukken zijn een aanwijzing (verse natte sporen naar een personeelsdeur: hier is net iemand binnengekomen) en een risico (een beveiliger kan jouw sporen opmerken; even op de mat blijven staan of droog wachten loont). Dit versterkt de pillars fysieke wereld en onzichtbaarheid.
- **Techniek**: per kamer een afdruklaag (een textuur waarop afdrukken gestempeld worden), met een shader die vervaagt over tijd. Maximaal circa 200 actieve afdrukken per kamer; de oudste verdwijnen eerst.

**7. Ramen en de buitenwereld**

Door elk raam beleef je de stad buiten: wat je ziet, hoort en voelt hangt af van het moment, het weer en vooral van waar het raam zít. Realisme is een harde regel: wat buiten gebeurt, moet kunnen gebeuren op die plek en die hoogte.

**Raamgegevens** (per raam vastgelegd door de level-designer)

- *Verdieping* en hoogte boven straatniveau.
- *Wat erachter ligt*: straat (en hoe druk), binnenplaats, rivier, spoor of tram, plein, bouwplaats, start- of landingsbaan.
- *Wat er direct voor staat*: boom, overburen, niets.
- *Open of dicht*, met of zonder gordijn of lamellen.

**Gebeurtenissen en hun voorwaarden**

| Gebeurtenis | Alleen als |
| --- | --- |
| Koplampen die over muur en plafond strijken | Begane grond t/m 2e verdieping, raam aan een straat met verkeer, avond of nacht |
| Tram- of metrolicht en gerommel | Raam aan een tram- of spoorlijn, binnen de dienstregeling |
| Scheepslichten, misthoorn | Raam met zicht op de Maas of de haven |
| Knipperlichten van vliegtuigen | Locatie bij de aanvliegroute; niet tijdens de nachtsluiting van het vliegveld |
| Lichten van overburen die aan- en uitgaan | Er staat bebouwing tegenover op vergelijkbare hoogte |
| Erasmusbrug of skyline als lichtlijn | Hoge verdieping of open zicht in die richting |
| Vuurwerk | Nieuwjaarsnacht en de nachten erna (losse knallen), niet meer later in de week |
| Straatgeluid luid en helder | Raam open; dicht = gedempt en dof |
| Wind: dode bladeren, papiertjes, vuurwerkresten die naar binnen waaien | Raam open, lage verdieping, er staat een boom of er ligt rommel op straat; in januari vooral dode bladeren en vuurwerkresten, geen vers herfstblad |
| Gordijn dat beweegt | Raam open en wind |
| Regen op het glas (druppels, strepen) | Het regent; harder bij wind en op hoge verdiepingen |
| Sirenes, stemmen, scooters, een vechtpartij in de verte | Straat met nachtleven in de buurt; het verst hoorbaar bij een open raam |

**Tijd van de dag**: de game speelt vooral 's nachts, maar de schemering, de nacht en de zonsopgang (finale) kleuren het licht door de ramen anders.

**Controle**: een script toetst alle raamgebeurtenissen per kamer aan de raamgegevens. Koplampen op de 20e verdieping of bladeren door een dicht raam laten de check rood worden.

**8. Elektrische apparaten**

Apparaten werken echt. Je zet ze aan en uit, ze doen wat ze in het echt doen, en ze hebben invloed op licht, geluid en de wereld om je heen. Een koffiemachine zet koffie; een lampknop schakelt, en dimt als er een dimmer zit.

**Apparaatmodel** (data per apparaat)

- *Toestanden*: uit, standby, aan, bezig, kapot. Elke toestand heeft een eigen materiaal of model, licht, audio-cue en beschrijving.
- *Bediening*: schakelaar, draaiknop of dimmer, drukknop, afstandsbediening, of via een app op een telefoon (smart home).
- *Stroom*: aangesloten op een stroomgroep per kamer of verdieping. Een meterkast of hoofdschakelaar kan een hele groep uitzetten.
- *Proces*: wat het apparaat doet, hoe lang het duurt en wat het oplevert.
- *Benodigdheden*: wat het nodig heeft om te werken.

**Voorbeelden**

| Apparaat | Bediening | Wat het doet |
| --- | --- | --- |
| Plafondlamp in de studentenkamer | Schakelaar bij de deur | Aan/uit |
| Bureaulamp of sfeerlamp | Draaidimmer | Traploos dimmen; het licht in de kamer verandert mee |
| Tl-verlichting in het ziekenhuis | Schakelaar, per groep | Aan/uit, met even knipperen bij aanspringen; niet dimbaar |
| Koffiemachine | Knop | Heeft water en een kopje nodig; zet in ongeveer 30 seconden koffie (geluid, damp, lampje); levert het object "kop koffie" op |
| Waterkoker | Knop | Kookt water in ongeveer een minuut; schakelt zelf uit |
| Tv | Knop of afstandsbediening | Aan/uit, zenders wisselen (wisselt het lichtprofiel), volume |
| Laptop of computer | Aan-knop, wachtwoord | Opstarten, inlogscherm; bij standby wakker maken met een toets |
| Lift | Knoppen, toegangspas | Roepen, verdieping kiezen, deuren open/dicht |
| Smart-homelamp | App op een gevonden telefoon | Aan, uit, dimmen, kleur |

**Regels**

- **Realisme**: dimmen alleen waar een dimmer logisch is (sfeerlampen, slimme lampen, hotel- en woonkamers), niet bij tl-verlichting of een lichtknop in een trappenhuis. Elk apparaat gedraagt zich zoals het in het echt doet: een waterkoker schakelt uit, een tv zonder stroom blijft zwart, koffie zonder kopje gaat niet.
- **Functioneel of duidelijk decor**: elk apparaat dat interactief oogt, werkt ook. Pure decor-apparaten worden niet gehighlight.
- **Koppeling met andere systemen**: lampen en schermen sturen de lichtbronnen aan; elk apparaat roept audio-cues aan; licht dat aan staat is van buitenaf zichtbaar door de ramen; een uitgezette tv kan een NPC opvallen.
- **Persistentie**: de toestand van elk apparaat blijft bewaard per kamer.

**Gameplay**

- *Sfeer*: zelf het licht dimmen in je kamer, de waterkoker aanzetten om half drie 's nachts.
- *Puzzels*: koffie zetten voor de nachtportier om hem even bezig te houden; via de meterkast een verdieping donker maken; het licht uitdoen zodat je in het donker ongezien langs een raam komt; een smart-homelamp laten knipperen om iemand naar de gang te lokken.

**9. Kleding en uitrusting**

De hoofdpersoon kan van kleding wisselen. Wat hij draagt bepaalt hoe de wereld op hem reageert: wie hij lijkt te zijn, hoe herkenbaar hij is en hoe nat hij wordt. Kleding is daarmee een puzzelmiddel, geen cosmetica.

**Slots**

| Slot | Voorbeelden |
| --- | --- |
| Hoofd | Pet, muts, capuchon, fietshelm, bouwhelm, verpleegkapje |
| Bovenkleding | Hoodie, regenjas, bezorgjas, uniformjas, doktersjas, crewjasje |
| Over-laag | Veiligheidshesje, naamkaart of badgehouder |
| Handen | Handschoenen, werkhandschoenen, latex handschoenen |
| Voeten | Sneakers, werkschoenen, regenlaarzen, schoenhoesjes |
| Gedragen | Bezorgtas, rugzak, gereedschapskist, dienblad |

**Wat kleding doet**

- **Rol**: een complete outfit geeft een rol (bezorger, schoonmaker, bouwvakker, verpleegkundige, cateraar, crew). NPC's en toegang reageren op die rol. Een rol is geloofwaardig als drie dingen kloppen: de outfit is compleet, je bent op een plek waar die rol hoort, en het is een tijd waarop die rol daar werkt. Een half uniform of de verkeerde plek wekt argwaan.
- **Herkenbaarheid**: een pet, capuchon of helm verlaagt hoe herkenbaar je bent voor camera's en mensen die je eerder zagen. Dat raakt het thema: Het Hart ziet steeds meer.
- **Weer en vocht**: een regenjas en capuchon houden je droger; laarzen en schoenhoesjes bepalen je voetsporen (schoenhoesjes laten bijna niets achter, laarzen veel bij nat weer).
- **Opbergen**: jassen en tassen zijn containers (zie Objectsysteem); wat in de zakken zit, gaat mee als je de jas wisselt.

**Regels**

- **Omkleden kost tijd** (een paar seconden per slot) en kan alleen waar het logisch is: je eigen kamer, een toilet, een kleedkamer, een donkere hoek. Nooit waar een NPC je ziet.
- **Kleding is een object**: je vindt het in de wereld (kluisje, waslijn, garderobe, bouwkeet) en wat je uittrekt blijft liggen waar je het neerlegt. Uniformen liggen niet zomaar klaar; ze zijn een beloning van een puzzel.
- **Zichtbaar**: elke combinatie is zichtbaar aan het personage, opgebouwd uit lagen per slot.

**Gameplay-voorbeelden**

- Met een bouwhelm en hesje loop je over de bouwplaats in Katendrecht zonder dat iemand iets vraagt.
- Een schoonmakersjas met een karretje geeft 's nachts toegang tot de gangen van het ziekenhuis.
- Schoenhoesjes voorkomen natte sporen op de linoleumvloer, die de beveiliging zou opmerken.
- Een crewjasje en badgehouder brengen je airside op het vliegveld, maar alleen als je ook het juiste tijdstip treft.

**10. Reizen met de metro**

De hoofdpersoon reist tussen locaties met de Rotterdamse metro, op de echte lijnen en met de echte stationsnamen. De metrokaart is de wereldkaart van de game.

**Locaties en stations** (vast te stellen en te controleren door de locatie-onderzoeker)

| Locatie | Station | Lijnen | Laatste stuk |
| --- | --- | --- | --- |
| Studentenkamer, Witte de Withstraat (hub) | Eendrachtsplein | A, B, C | Lopen |
| Katendrecht | Rijnhaven | D, E | Lopen; overstappen op Beurs |
| Woontoren aan de Maas | Wilhelminaplein | D, E | Lopen |
| Markthal / Centraal | Blaak of Rotterdam Centraal | A, B, C / D, E | Lopen |
| Maasvlakte | Geen metro | — | Lijn B naar het westen, daarna bus of meerijden; uit te zoeken |
| Erasmus MC | Dijkzigt | A, B, C | Lopen; één halte van de hub |
| Delfshaven | Delfshaven | A, B, C | Lopen |
| Vliegveld | Meijersplein / Airport | E | Bus of fiets; de metro stopt niet bij de terminal |

**Hoe een reis werkt**

- **Kaart**: je kiest op een eigen, schematische metrokaart een bestemming die je kent (uit een order, een bericht of een gesprek). De kaart volgt de echte lijnen, kleuren en stations, maar is zelf getekend.
- **Perron**: een korte, speelbare scène. Wachten, mensen, reclames, het tijdsbord, de trein die binnenrijdt. Elk station heeft een eigen herkenbaar detail.
- **De rit**: een kort tussenstuk in de wagon: tunnellichten, of de stad als de lijn bovengronds rijdt, medereizigers, een overstap op Beurs waar dat echt moet. Overslaan kan na de eerste keer.
- **Tijd**: een reis brengt je naar een volgende scène met een latere tijd op de klok, realistisch per afstand en overstap.

**Realisme**

- **Dienstregeling**: de metro rijdt niet de hele nacht. Nachten beginnen daarom in de avond met een metroreis; na de laatste metro gaat de hoofdpersoon op zijn bezorgfiets. Exacte tijden en de dienstregeling rond oud en nieuw worden door de locatie-onderzoeker uitgezocht.
- **Geen metro waar die er niet is**: de Maasvlakte en de terminal van het vliegveld vragen een laatste stuk met bus of fiets.
- **Echte stationsnamen en lijnkleuren**, maar geen officiële logo's, huisstijl of kaartontwerp van de vervoerder; een fictieve vervoerder en ov-kaart, tenzij er een licentie komt (zie Open vragen).

**Verhaal**: de reclames op de perrons zijn een verhaalkanaal. Elke nacht hangen er meer affiches van Het Hart, tot het hele perron ervan vol hangt.

**Hintsysteem**: de hoofdpersoon mompelt bij stilstand een gedachte, afgeleid uit de afhankelijkheidsgraaf (de eerstvolgende open knoop). Drie niveaus: vaag, richting, bijna expliciet.

## Interface en besturing

De interface is minimaal: het speelveld vult het scherm, alles anders schuift in wanneer je het nodig hebt.

| Element | Ontwerp | Verschil met DreamWeb |
| --- | --- | --- |
| Speelveld | Volledig scherm, 16:9, camera volgt in kleine ruimtes niet | Origineel had een klein venster |
| Vergrootglas | Hover toont ingezoomde detailweergave in een hoek | Behouden, het is een sterk idee |
| Interactie-highlight | Spatiebalk toont alle interactieve objecten | Nieuw: geen pixel hunting |
| Inventaris | Strook onderin, slepen naar containers | Containers behouden |
| Telefoon | Eigen telefoon als menu; gevonden apparaten openen als scherm | Vervangt de oude terminals |
| Notitieboek | Tabblad in eigen telefoon: personen, plekken, codes | Nieuw |

**Besturing**: muis als primair (links: lopen/gebruiken, rechts: bekijken). Controller- en Steam Deck-ondersteuning later, met een cursor die naar objecten snapt.

**Klok en datum**: rechtsboven in beeld staat altijd een klok met datum, bijvoorbeeld *za 1 jan · 00:07*. De klok staat stil op de tijd van de scène; hij tikt niet mee terwijl je speelt.

- **Tijd springt per scène**: elke scène heeft een vast tijdstip, vastgelegd door de level-designer. Na een reis, een droom of een kamerwissel die tijd kost, toont de klok de nieuwe tijd.
- **Binnen een scène**: wat er gebeurt (drogende schoenen, koffie zetten, NPC-routines zoals de pauze van een beveiliger) loopt als gebeurtenis in de scène, niet als klok. Timing-puzzels draaien om wat je ziet gebeuren, niet om minuten.
- **Alles volgt de scènetijd**: licht door de ramen, dienstregeling van de metro, open en dicht van winkels en het vliegveld, de kerstresten per nacht en het tv-programma.
- **Regie**: een tijdsprong wordt zichtbaar door de klok die verspringt; bij de twee niet-lineaire momenten loopt de klok zichtbaar terug.

**Ontwikkelvensters** (alleen in ontwikkelbuilds): F2 toont het geluidsvenster met alle verwachte geluiden (zie Art direction en audio). Hier kunnen later ook andere vensters bij, zoals flags en de puzzelgraaf.

## Art direction en audio

De look is low-poly 3D met vlakke kleuren (geen texturen) en sterk realtime licht, gezien door een vaste schuine camera van bovenaf: aantrekkelijk zonder complex te ogen. De sound is trage synth die bij geweld omslaat in vervormde gabber. Maatstaf is de stijltest in `proto/stijltest/`; details staan in `docs/stijlgids.md`.

**Visueel**

- Engine: Godot 4 in 3D, renderer Forward+.
- Camera: vast per kamer, schuin van boven (circa 38° omlaag, 20–35° gedraaid om de verticale as), perspectief met smalle FOV (15–20°) zodat het bijna orthografisch oogt. Alleen buitenruimtes die groter zijn dan het eiland schuiven traag mee met Richard, met dezelfde hoek.
- Resolutie: native 1080p en 1440p, geen lage interne resolutie. De lichte kwaliteitsstand mag de render scale verlagen.
- Schaal: 1 unit = 1 m. Een tile is een vak van 1×1 m in de content (looproutes, collision, plaatsing). Personages zijn circa 1,80 m en altijd minstens 80 px hoog op 1080p.
- Vormtaal: eenvoudige low-poly vormen in vlakke kleuren uit het palet; geen foto's, geen fotomaterialen. Detail komt uit vorm, licht en reflectie.
- Palet bovenstad: koud blauw en natriumoranje, neon-accenten (magenta, cyaan). Palet onderstad: sepia/grijs met één rode kleur. Dat droomrood verschijnt hooguit één keer per hoofdstuk in de bovenstad, als bewust twijfelsignaal (pillar 4).
- Licht: realtime Godot 3D-lichten met schaduw; glow alleen op lichtbronnen; nat via lage roughness, reflectieprobes en SSR; lichtkegels via lokale mist; regen als particle-laag; de Erasmusbrug als lichtlijn in de verte waar het past.
- Herkenbaarheid: elke locatie heeft 1 icoon-element (Markthal-boog, Katendrechtse pakhuizen, containerkranen, terminalgebouw).

**Prestaties: twee kwaliteitsstanden**

Het spel moet ook op een gewone laptop draaien. De stijltest haalde 170 fps alleen op een RTX 4080; dat is geen maat. Elk beeld moet in de lichte stand nog werken: de sfeer mag niet afhangen van SSR of volumetrische mist.

| | Volle stand | Lichte stand |
| --- | --- | --- |
| Doel | 60 fps op 1080p, middenklasse-gpu (GTX 1660, RTX 3050 laptop) | Minstens 30 fps op 1080p, laptop met geïntegreerde gpu (Iris Xe, Radeon 680M) |
| Render scale en anti-aliasing | 1,0 met MSAA 4× | 0,75 met FSR, FXAA |
| Volumetrische mist | Aan, plus een lokaal mistvolume per lantaarn | Uit; lichtkegels als goedkope additieve mesh |
| SSR | Aan | Uit; reflectieprobes en reflectiestrepen dragen het nat |
| SSAO | Aan | Uit |
| Glow | Aan | Aan |
| Lichten met schaduw in beeld | Hooguit 6 | Hooguit 3 (de rest zonder schaduw) |
| Regendeeltjes | Circa 6000 | Circa 2000 |

- Budget per scène, beide standen: hooguit 300 losse meshes (kleine dingen samenvoegen), hooguit 16 lichten in beeld, hooguit 6 levende lichtbronnen per kamer.
- Bij de eerste start meet de game kort en kiest een stand; wisselen kan in het menu.
- QA meet per kamer de fps in beide standen. Referentie voor de lichte stand: een gewone laptop met Intel Iris Xe.

**Kadrering en detail: beklemmend én rijk**

Beklemming komt uit de kadrering, niet uit weinig detail. Een kleine kamer die vol staat voelt benauwder dan een lege.

1. **Klein verlicht eiland in een donker kader.** Een kamer is klein (richtwaarde 4×5 tot 10×8 m) en beslaat hooguit 60 % van de beeldbreedte en 70 % van de hoogte. Daaromheen: duisternis en vignet. Wat buiten het eiland ligt, wordt niet gemodelleerd of valt weg onder 5 % helderheid; voorwanden zijn weggesneden tot een lage donkere rand. Het DreamWeb-venster, maar als bewuste regie.
2. **Drie lagen detail.** Kamerbeeld (sfeer, licht, silhouetten, dicht gevuld); vergrootglas bij hover (een tweede camera toont het object groter, in hetzelfde licht); close-up panelen op sleutelmomenten (handwerk, sluit aan op de Regiestijl). De speler kiest hoe diep hij kijkt.
3. **Licht bepaalt waar detail zit.** Lichtplassen van natriumlampen, schermen en neon tonen alles; de rest zakt weg in schaduw. Kleine objecten en afgeschuinde randen staan alleen in het licht; in de schaduw grote, eenvoudige vormen.
4. **Voorgrond knijpt het beeld af.** Dakranden, leidingen, gordijnen en stellingen staan als echte geometrie tussen camera en kamer, als donker silhouet: je kijkt ergens doorheen.
5. **Leesbaarheid gaat voor.** Decor is iets ontzadigd; interactieve objecten krijgen een subtiele contour in het highlight-wit; de spatiebalk toont alles wat interactief is. Geen interactief object en geen looproute in een zone die donkerder is dan 15 % helderheid.
6. **Ritme: benauwd tegenover leeg.** Elk hoofdstuk heeft waar mogelijk één open, lege ruimte als contrast (containerterrein, platform, uitzicht op de Erasmusbrug). Na de krappe kamers voelt die eenzaam, niet bevrijdend.
7. **Detail uit kits.** Per locatie één kit met low-poly rommel (studentenkamer, bouwplaats, ziekenhuis, haven); de asset-pipeline plaatst die per kamer.

**Rotterdam zichtbaar maken, van bovenaf**

Van bovenaf zie je vooral vloeren, bedden, tafels en daken, en weinig gevels. Daarom brengen we Rotterdam in beeld via wat horizontaal ligt en via kleur en vorm, in elke kamer waar dat logisch is.

**Regels**

- **Logisch voor eigenaar en plek**: elk Rotterdam-element past bij wie daar woont of werkt. Een student heeft andere dingen dan een projectontwikkelaar; een ziekenhuisgang heeft er bijna niets.
- **Een tot drie per kamer**: genoeg om het te voelen, nooit een toeristenwinkel.
- **Op horizontale vlakken**: vloerkleden, dekbedden, tafels, bureaus, aanrechten, daken en straten. Op muren alleen op de wanden die de camera ziet.
- **Herkenbaar aan kleur en vorm**: rood-wit (de club), groen-wit-groen (de stadsvlag), de zwaan-vorm van de Erasmusbrug, de boog van de Markthal, havenkranen, de kubuswoningen.
- **Echte merken en clubs**: herkenbaar via kleuren en vormen, zonder echte logo's, tenzij er een licentie is (zie Open vragen).

**Voorbeelden per locatie**

| Locatie | Wat logisch en mogelijk is |
| --- | --- |
| Studentenkamer (hub) | Rood-wit vloerkleed, clubsjaal over de stoel, een leeg kapsalon-bakje op het bureau, een fietskaart van de stad, het uitzicht op illegaal vuurwerk boven de daken |
| Bar Witte de Withstraat (dicht) | Bierviltjes met de skyline, een stadsvlag achter de bar, stoelen op de tafels, een tv die uit staat |
| Katendrecht | Klinkers in keperverband, oude kaaimuren en bolders, de achterdeur van een illegale bar, maquette van de nieuwe wijk in de loft van de ontwikkelaar, ingelijste luchtfoto van de haven |
| Woontoren aan de Maas | Uitzicht op de rivier en de brug vanaf het penthouse, design-vloerkleed met een abstracte plattegrond van de stad |
| Markthal / Centraal | De beschilderde boog van de Markthal als plafondrand, het dak van Centraal als herkenbare vorm, kapsalon-tentje |
| Maasvlakte | Containers in rijen, kranen, de lijnen op het asfalt, schepen aan de kade |
| Erasmus MC | Bijna niets: een stadsposter in de wachtruimte, het uitzicht vanaf het dak over de stad |
| Delfshaven | Grachten, oude pakhuizen, de molen en kerk van bovenaf |
| Vliegveld | Stadsposter in de vertrekhal, de skyline als lichtlijn in de verte bij zonsopgang |

**Net na kerst: seizoensdetails**

De game speelt in de eerste week van januari. Kerst is net voorbij, en dat zie je overal een beetje: niet feestelijk, maar als resten van een feest dat over is. Dat versterkt de eenzaamheid van de hoofdpersoon.

**Regels**

- **Logisch per plek en eigenaar**: wie versiert er, en hoeveel? Een student weinig, een lobby van een woontoren strak en duur, een haventerrein bijna niets.
- **Resten, geen feest**: lampjes die nog hangen, een boom die naalden verliest, een half losgeraakte slinger, kerstkaarten op een kast, lege verpakkingen.
- **De tijd loopt door**: de versiering verdwijnt in de loop van de zeven nachten. Rond Driekoningen (6 januari) staan kerstbomen op straat bij de inzamelpunten.
- **Gekoppeld aan systemen**: kerstlampjes zijn elektrische apparaten (aan, uit, knipperend) en levende lichtbronnen; naalden zijn een decal op de vloer; een kerstboom op straat is een object.

**Per locatie**

| Locatie | Wat logisch is |
| --- | --- |
| Studentenkamer | Eén snoer lampjes langs het raam, een kerstkaart van thuis op het bureau (bij het ongeopende bericht) |
| Trappenhuis studentenhuis | Een boompje dat de huisgenoten hebben achtergelaten, verdroogd, met naalden op de mat |
| Bar Witte de Withstraat | Lampjes boven de bar die in de dichte zaak blijven branden, een half losgeraakte slinger, een kerstmuts op de tap |
| Katendrecht | Lichtjes in een paar ramen, een kerstboom naast de container |
| Woontoren aan de Maas | Strakke designboom in de lobby, verdwijnt halverwege de week |
| Markthal / Centraal | Grote winterverlichting die nog brandt, wordt in de loop van de week afgebroken |
| Maasvlakte | Een snoer lampjes in de kantine of het portiershokje, verder niets |
| Erasmus MC | Bescheiden: een klein boompje bij de balie, papieren sterren op het raam van een afdeling |
| Delfshaven | Lichtjes in de oude huizen langs het water |
| Vliegveld | Een boom in de vertrekhal; op de zevende ochtend weg |

**Vloeren en oppervlakken: rijk en nooit eentonig**

Vloeren vullen het grootste deel van elk beeld, dus herhaling en eentonige vlakken vallen daar het eerst op. Zonder texturen komt variatie uit geometrie, tinten, roughness en decals.

1. **Elke vloer is uniek.** De vloer van elke kamer is eigen geometrie (planken, tegels, klinkers als vlakken) met 2 à 4 tinten uit de materiaalladder, per vlak gekleurd. Grote open ruimtes krijgen hun variatie uit een gedeelde vloer-shader met ruis in wereldcoördinaten, afgerond naar de ladder; nooit een zichtbaar herhalend patroon.
2. **Echte patronen als bron.** De locatie-onderzoeker levert patroon en maat (klinkers in keperverband, stoeptegels 30×30, ziekenhuislinoleum, laminaat, de steen van de Markthal, havenbeton met roosters, tapijt op het vliegveld). We modelleren het patroon, niet de foto.
3. **Slijtage die vertelt.** Looppaden zijn een tint anders en glanzen iets meer, randen en hoeken zijn donkerder, onder verschoven meubels zit verkleuring.
4. **Decal-laag.** Godot-decals met alleen een vormmasker (geen foto), kleur uit het palet: vlekken, scheuren, kauwgom, peuken, tape-markeringen, bladeren, naalden, vuurwerkresten; deels willekeurig, deels bewust als aanwijzing.
5. **Nat en licht.** Buiten is alles nat: asfalt en klinkers met lage roughness, plassen als donkere vlakken die bijna spiegelen en alleen licht tonen als er licht in valt (reflectieprobes, SSR, reflectiestreep per lichtbron, regenringen). Elke lichtbron buiten heeft een zichtbare reflectie, ook in de lichte stand. Binnen tonen vloeren de natte voetsporen van het vochtsysteem als glanzende decals (zie Systemen).
6. **Palet-discipline.** Albedo alleen uit het palet, per materiaal een vaste ladder van 3 à 5 tinten, geen fotoruis. Alle verdere kleur komt uit licht. Vloeren onder sleutelmomenten worden met de hand bijgewerkt.
7. **Herhalingstest.** De art-director bekijkt per kamer een 1080p-screenshot, uitgezoomd, en zoekt naar patronen, strepen en eentonige vlakken.

**Levende lichtbronnen: schermen die echt lijken**

Tv's, monitoren, telefoons en neon zijn geen vaste lampen. Hun licht wisselt in kleur en intensiteit, zodat je voelt dat er echt iets op staat, ook als je het scherm zelf niet ziet.

| Bron | Gedrag van het licht |
| --- | --- |
| Tv | Scènewissels om de 2 à 8 seconden (abrupte kleur- en helderheidssprong), binnen een scène lichte flikkering en kleine dips. Gekoppeld aan geluid uit de tv. |
| Computer | Rustig koel licht; korte verschuivingen als er een venster wisselt; heel lichte flikkering bij typen; screensaver laat het licht traag drijven; standby-ledje knippert. |
| Telefoon | Licht het gezicht en de handen op in het donker; korte flits bij een melding. |
| Neon | Stabiel, met af en toe een haperende flikkering en een zoem. |

**Tv-profielen**: elk soort uitzending heeft een eigen lichtprofiel, zodat het herkenbaar is zonder beeld.

- *Nieuws*: koel blauw-wit, rustig, regelmatige harde cuts.
- *Voetbal*: groen overheersend, lange rustige stukken, af en toe een opleving.
- *Film*: warm en donker, met plotselinge felle flitsen.
- *Reclame*: snelle, verzadigde kleurwissels.
- *Geen signaal / standby*: grijze ruis of een vaste donkerblauwe gloed.

**Regels**

- Elk scherm heeft een eigen startpunt (seed), dus twee tv's in dezelfde kamer lopen nooit synchroon.
- Het licht valt op muren, plafond, vloer en gezichten; objecten werpen schaduwen van het schermlicht.
- Kom je dichtbij of open je een close-up, dan matcht wat je op het scherm ziet met het lichtprofiel.
- Lichtprofielen worden procedureel gemaakt of afgeleid uit eigen beeldmateriaal, nooit uit echte uitzendingen of films.

**Gameplay en verhaal**

- Een tv die aan staat of schermlicht onder een deur betekent: hier is iemand, of hier was net iemand.
- Tv's en radio's zijn een verhaalkanaal: het nieuws over Het Hart schuift elke nacht verder op (aankondiging, discussie, aftellen). Dat sluit aan op de Regiestijl (muziek en geluid uit de wereld).
- Maximaal circa 6 levende lichtbronnen per kamer, om leesbaarheid en prestaties te bewaken.

**Audio**

- Verkennen: trage, donkere synths en ambient (regen, verkeer, schepen in de verte).
- Spanning: lage drones, hartslag.
- Geweld en droomovergangen: vertraagde, vervormde gabberkicks, een knipoog naar Rotterdam als bakermat van hardcore.
- Stemmen: geen voice-over in de eerste versie; ambient stemmen en korte geluiden per NPC.

**Productie van geluid**

Geluid komt uit vijf bronnen, in deze volgorde van voorkeur. Elk bestand wordt met bron en licentie vastgelegd in `audio/licenties.md`.

| Bron | Waarvoor | Let op |
| --- | --- | --- |
| Eigen veldopnames in Rotterdam | Tram en metro, schepen en misthoorn, wind op de Erasmusbrug, regen op ramen, Markthal, stations, straten met nachtleven | Het meest authentiek; een handrecorder of goede telefoon met windkap volstaat; geen herkenbare gesprekken van voorbijgangers gebruiken |
| Vrije bibliotheken | Basis voor effecten: deuren, liften, objecten, voetstappen | Alleen CC0 van Freesound en de jaarlijkse gratis GDC-bundels van Sonniss; andere bibliotheken (zoals BBC Sound Effects) zijn vaak alleen voor niet-commercieel gebruik |
| Synthese in code | Brom van apparaten, tv-ruis, piepjes, UI, drones, de vervormde kicks | Python-scripts (numpy, scipy) of SuperCollider; een agent kan deze volledig schrijven en varianten maken |
| AI-geluidsgeneratie | Losse, moeilijk te vinden effecten | Alleen met een licentie die commercieel gebruik toestaat; per bestand vastleggen |
| Componist of jijzelf | Muziek: synths en gabber-lagen | Agents leveren structuur, briefs en implementatie, niet de muziek zelf |

**Bewerking (volledig gescript)**: knippen, fades, ruis eruit, normaliseren naar vaste luidheid per bus (LUFS), naadloze loops via crossfade, exporteren naar OGG. Gereedschap: ffmpeg, sox en Python.

**Variatie in de game**

- Voetstappen: 6 à 10 opnames per vloermateriaal, willekeurig gekozen met kleine toonhoogte- en volumevariatie (Godot AudioStreamRandomizer). Natte schoenen voegen een soppende laag toe, in sterkte gekoppeld aan de nat-waarde.
- Ambiences: losse lagen (regen, stad, apparaten) die per kamer gemengd worden en in tijd verschuiven, zodat geen loop herkenbaar wordt.
- Ruimte: galm per kamergrootte en vloermateriaal; low-pass-filter bij dichte ramen; vaste bussen voor muziek, effecten, ambience en stemmen.

**Fasering: eerst stil, met een geluidsvenster**

In de eerste iteraties wordt nog geen geluid gemaakt. Wel roept de game overal waar geluid hoort een *audio-cue* aan. Een geluidsvenster laat tijdens het spelen zien welk geluid er op dat moment verwacht wordt. Later wordt geluid cue voor cue toegevoegd, zonder iets aan de game zelf te veranderen.

- **Audio-cues**: elk geluid heeft een id in de cue-catalogus `audio/cues.json`, met beschrijving, laag (effect, voetstap, ambience, muziek, stem), bron in de wereld, prioriteit en status (*verwacht*, *placeholder*, *klaar*). Code en content roepen alleen cue-id's aan, nooit bestanden.
- **Geluidsvenster** (aan/uit met F2, alleen in ontwikkelbuilds):
  - *Nu actief*: de lagen die doorlopen, zoals ambience "regen op glas, raam dicht", muziekstatus "verkennen", tv "nieuws".
  - *Gebeurtenissen*: een lopende lijst van losse geluiden met tijd, cue-id en context, bijvoorbeeld `voetstap.tegel.nat (nat 0,7)` of `deur.lift.open`.
  - *Ruimte*: de actieve galm en of het raamfilter aan staat.
  - Kleur per status: grijs = verwacht, geel = placeholder, groen = klaar.
- **Logboek**: elke speelsessie schrijft alle aangeroepen cues weg. Daaruit volgt automatisch de geluidsbacklog: welke cues het vaakst klinken, gaan het eerst.
- **Stap voor stap toevoegen**: per latere iteratie een blok cues (eerst voetstappen en regen, dan ambiences per locatie, dan muziek). Een cue gaat van *verwacht* naar *klaar* zodra het bestand bestaat en de audiocheck groen is.

**Productie: low-poly 3D voor Godot**

Kamers, objecten en personages zijn low-poly 3D-modellen die in Godot realtime worden belicht. Er wordt niets vooraf gerenderd. Dat geeft consistent perspectief, echt licht en snelle varianten. Handwerk volgt alleen waar het telt.

| Stap | Wat |
| --- | --- |
| 1. Modelleren | In Blender (bronnen in `art/blender/`) of, voor eenvoudige vormen, met Godot-primitieven in een scène. Low-poly volgens het budget in de stijlgids. Schaal 1 unit = 1 m, oorsprong op de grond in het midden (voetpunt), naam = object-id. |
| 2. Materialen | Vlakke kleur uit het palet, geen texturen. Gedeelde materialen per paletkleur en oppervlak (droog, nat, metaal, glas, emissief) in `game/assets/materialen/`; modellen verwijzen ernaar in plaats van eigen materialen te maken. Uitzonderingen: decal-maskers en beeldvlakken (affiche, scherm, kaart, bord) als kleine vlakke afbeelding in het palet. |
| 3. Exporteren | glTF 2.0 (`.glb`) naar `game/assets/<locatie>/`; bij import vervangt Godot de materialen door de paletmaterialen. Collision en navigatie worden in Godot gemaakt. |
| 4. Belichten | Alleen in Godot, nooit in Blender. Per locatie een lichtpreset en per scènetijd een omgevingsinstelling (ambient, mist, glow); per kamer de lampen als nodes. |
| 5. Kits | Per locatie een kit met losse objecten als Godot-scènes; de asset-pipeline plaatst ze per kamer volgens de levelbrief en voegt kleine statische dingen samen. |
| 6. Raster en decals | Het tile-grid (vakken van 1×1 m) blijft voor looproutes, collision en plaatsing in de content; de navigatiemesh wordt eruit gebakken. Objecten mogen binnen een vak vrij staan. De decal-laag ligt los op de geometrie. |
| 7. Personages | Eén basismodel met skelet; kleding per slot als losse mesh op hetzelfde skelet, gedeelde animaties, zodat elke combinatie werkt. |
| 8. Controleren | Per kamer een screenshot op 1080p in beide kwaliteitsstanden (script zoals in de stijltest) voor de art-review. |
| 9. Handwerk | Hoofdpersoon, sleutelobjecten, de herkenbare Rotterdam-elementen en de close-up panelen worden met de hand gemaakt of bijgewerkt, door jou of een 3D-artist of illustrator. |

Placeholders blijven eerst toegestaan: een hoofdstuk mag speelbaar zijn met grijze blokken, zolang licht, regen en audio de sfeer al dragen.

## Technische architectuur

Godot 4 met GDScript, een data-gedreven contentmodel en headless tests: zo kunnen agents content toevoegen en controleren zonder de engine-code te raken.

**Repositorystructuur**

```
onderstad/
  .claude/agents/        # agent-definities (zie Agent-specificaties)
  docs/                  # GDD, levelbriefs, stijlgids, lore-bijbel, personages/, locaties/, systemen/, art-briefs/, waarheid.md
  audio/                 # veldopnames, synthese-scripts, licenties.md
  art/blender/           # .blend-bronbestanden en exportscripts (glTF naar game/assets/)
  game/                  # Godot-project
    systems/             # objecten, toegang, state, dialoog, telefoon
    scenes/rooms/        # kamers per locatie (.tscn)
    ui/
  content/               # ALLE content als data
    spel.json            # startdatum, hoofdstukvolgorde, slots, talen, globale flags en condities
    tekst/<taal>/*.json  # alle spelerszichtbare tekst; content bevat alleen sleutels
    chapters/ch00_hub/   # de hub is een eigen hoofdstuk
    chapters/ch01_katendrecht/
      chapter.json       # flags, doelwit, volgorde
      rooms/*.json       # objecten, deuren, NPC's per kamer
      puzzles.json       # afhankelijkheidsgraaf
      dialogue/*.json
      devices/*.json     # telefoons, panelen, mails
    items.json
  tools/                 # validators, oplosser, asset-pijplijn (Python)
  tests/                 # GUT-tests + headless playthroughs
```

**Kernkeuzes**

- **Content in JSON** met een JSON Schema per type. Validatie in CI en lokaal.
- **Puzzelgraaf als bron van waarheid**: knopen = acties/feiten, kanten = vereisten. Een Python-oplosser bewijst dat elk hoofdstuk oplosbaar is en dat er geen doodlopende staat bestaat, binnen een vereenvoudigd model (zie docs/systemen/state-en-flags.md, "De oplosser"); elke run meldt welke beperkingen gelden.
- **Headless playthrough**: Godot draait zonder scherm een opgenomen oplossingsscript af (`godot --headless`) en meldt of het einde van het hoofdstuk bereikt wordt.
- **Tests**: GUT (Godot Unit Test) voor systemen.
- **Versiebeheer**: Git op GitHub; elke agent werkt op een branch; merge na review en groene checks.
- **Lokalisatie**: alle teksten via sleutels, zodat een Engelse versie later kan.

## Vertical slice: hoofdstuk 1, Katendrecht

De vertical slice is 20 à 30 minuten speeltijd van hub tot eerste droom, met definitieve sfeer en placeholder-art waar nodig.

**Verloop**

1. **Kamer (hub)**: nieuwjaarsnacht, alleen op zijn studentenkamer, illegaal vuurwerk boven de daken. Verken de kamer; het vuurwerk gaat over in de eerste droom. Daarna wakker: leer pakken en gebruiken. Pak bezorgtas en jas.
2. **Order**: Richard slaapt de dag door. Zaterdagavond rond 21:00 toont de app een order naar een adres in Katendrecht, op een naam uit de droom.
3. **Katendrecht, buiten**: verbouwd pakhuis met bouwhekken. Bij een bankje ligt een verloren telefoon.
4. **Telefoon kraken**: de pincode staat niet op het toestel maar volgt uit een foto in een bar (verjaardagstaart op een social-post). Door de lockdown is die bar officieel dicht; achterom draait hij in het geheim door, alleen voor genodigden. Binnenkomen is zelf een kleine toegangspuzzel.
5. **Toegang**: via berichten op de telefoon vind je de toegangscode van de bouwlift en het tijdstip waarop de beveiliger pauzeert.
6. **Binnen**: loft van de ontwikkelaar; maquettes van de nieuwe wijk, een foto van zijn vader in de haven (de menselijke kant).
7. **Confrontatie**: kort, buiten beeld, geluid valt weg.
8. **Droom**: in de onderstad komt één gebouw terug.

**Wat de slice moet bewijzen**

- [ ] Objectsysteem met containers werkt (tas, jas, telefoon)
- [ ] Telefoon-puzzel is oplosbaar zonder hint door 3 van de 5 testers
- [ ] Toegangssysteem met code + timing werkt
- [ ] Droomovergang zonder laadscherm
- [ ] Sfeer: testers beschrijven de game spontaan als "donker", "Rotterdam" of "eenzaam"
- [ ] Oplosser en headless playthrough draaien groen

**Content-omvang**: 6 kamers (studentenkamer, trappenhuis, bar, Katendrecht-plein, pakhuis-lobby, loft), 1 droomkamer, ongeveer 30 objecten, 4 NPC's, 2 apparaten, 5 puzzelknopen.

## Roadmap

Vijf fases, elk afgesloten met een poort. Pas na de vertical slice beslis je of de formule werkt en investeer je in hoofdstukken en definitieve art.

| Fase | Inhoud | Poort naar de volgende fase |
| --- | --- | --- |
| 0 · Fundament | Repo, JSON-schema's, agents, objecten/toegang/state, validator en oplosser | Systemen getest, oplosser draait |
| 1 · Vertical slice | Hub + hoofdstuk 1 Katendrecht, telefoon-puzzel, eerste droom | Slice-checklist groen, 5 testers hebben gespeeld |
| 2 · Hoofdstukken 2–4 | Woontoren, Markthal/Centraal, Maasvlakte; hintsysteem | Elk hoofdstuk door de definition of done |
| 3 · Hoofdstukken 5–7 | Erasmus MC, Delfshaven, vliegveld; het einde | Volledige playthrough van begin tot einde |
| 4 · Afronding | Definitieve art en audio, externe testers, bugfixes, release-build | — |

Martijn steekt er 2 à 4 uur per week in; een hoofdstuk-iteratie duurt daardoor eerder 3 à 4 weken dan 1 à 2. De fases hebben bewust geen data.

**Startpakket** (aan te leveren door Martijn vóór of tijdens Fase 0)

Nodig vóór de eerste iteratie:

- [ ] Hoofdpersoon in de basis: naam, leeftijd, studie, waarom alleen met oud en nieuw, wat er in het ongeopende bericht van thuis staat
- [ ] Eerste personageblad van doelwit 1 (projectontwikkelaar) en korte schetsen van buurvrouw, barman en beveiliger van de bouwplaats
- [ ] Stemvoorbeeld: één pagina eigen dialoog en objectbeschrijvingen als anker voor de schrijver
- [x] 5 à 10 visuele referenties (games, Rotterdam bij nacht, palet) als basis voor de stijlgids
- [x] Technische keuzes: Godot 4.7.2, Blender 5.2.3, repo Tackinardie/Dreamweb-Rotterdam, Windows 11, CI ja
- [x] Fictief universum: Bringbroh (bezorgapp), VrachtGo (vervoerder), MaasLijn (openbaar vervoer), Crispy & Co (snackbar), BB-drink (energiedrank), Havenlicht (sigaretten), Kardia (officiële naam van Het Hart)

Nodig voor de planning (kan in iteratie 1):

- [x] Tijdsbudget: 2 à 4 uur per week
- [x] Releasedoel: hobby (zie Risico's: wie later wil uitbrengen, moet bronnen en licenties opnieuw nalopen)
- [ ] Vijf testers voor de vertical slice

Kan bewust wachten: waan of waarheid, wie de orders stuurt, titel, Engelse versie, definitieve art, details van hoofdstuk 2 tot en met 7.

## Agent-ontwerp: overzicht

De ontwikkeling draait op veertien Claude Code-subagents onder een producer (de hoofdsessie), met een harde scheiding tussen makers en controleurs. Jij bent de laatste poort.

| Fase | Agents |
| --- | --- |
| Regie | Producer: hoofdsessie Claude Code met /iteratie |
| Ontwerp | verhaalarchitect, locatie-onderzoeker, systems-designer, level-designer, puzzle-designer, schrijver |
| Bouw | godot-engineer, asset-pipeline, geluidsontwerper |
| Controle | qa-tester, lore-keeper, art-director, playtest-criticus, code-reviewer |
| Jij | verhaalkeuzes, spelen en luisteren, merge naar main |

Rood of blokkerend: terug naar de maker, maximaal 3 rondes.

Ontwerp, bouw en controle lopen per iteratie in deze volgorde; QA-fouten of blokkerende reviews gaan terug naar de maker.

**Waarom zo**

- **Eén verantwoordelijkheid per agent**: korte, scherpe instructies geven betere output dan één alleskunner.
- **Data als contract**: agents praten via bestanden met schema's (rooms, puzzles, dialogue, devices), niet via elkaars context.
- **Niemand keurt eigen werk**: QA, lore, criticus en reviewer maken niets en krijgen alleen de bestanden.
- **Automatische waarheid**: validator, oplosser en headless playthrough bepalen of iets werkt, niet het oordeel van de maker.
- **Subagents roepen geen subagents aan**: de producer (hoofdsessie) orkestreert alles.

## Agent-specificaties

Veertien subagents voor Claude Code, elk met één verantwoordelijkheid, vaste input en vaste output. Zet elke definitie als bestand in `.claude/agents/<naam>.md`.

| Agent | Verantwoordelijk voor | Leest | Schrijft | Model |
| --- | --- | --- | --- | --- |
| verhaalarchitect | Verhaalboog, personages, waarheid; samen met Martijn | GDD, personages, waarheid | docs/personages/\*.md, docs/waarheid.md, docs/verhaal-open.md | opus |
| locatie-onderzoeker | Echte Rotterdamse details per locatie, met bronnen | GDD, levelbrief | docs/locaties/\*.md | opus |
| systems-designer | Ontwerp van spelsystemen: inventaris, telefoon, toegang, hints, opslaan, voetsporen, licht, ramen | GDD, bestaande specs | docs/systemen/*.md, tools/schemas/*.json | opus |
| level-designer | Hoofdstukbrief en kamerindeling | GDD, lore-bijbel, personages, locatiedossier | docs/levels/chNN.md, content/.../rooms/\*.json | opus |
| puzzle-designer | Afhankelijkheidsgraaf en puzzels | levelbrief, rooms, systeemspecs | content/.../puzzles.json | opus |
| schrijver | Dialogen, berichten, mails, beschrijvingen, tv- en radioteksten | brief, graaf, lore, personages | dialogue/*.json, devices/*.json | opus |
| godot-engineer | Systemen en scenes bouwen in GDScript | systeemspecs, schema's | game/, tests/ | sonnet |
| asset-pipeline | Productie van art via Blender en placeholders | stijlgids, art-briefs | art/blender/, game/assets/, docs/asset-lijst.md | sonnet |
| geluidsontwerper | Effecten, voetstappen, ambiences, ruimtelijk geluid, muziekstructuur | GDD, levelbrief, locatiedossier, systeemspecs | audio/, game/assets/audio/, audio/licenties.md, docs/audio-luisterlijst.md | sonnet |
| qa-tester | Validatie, oplosser, headless playthrough, audio- en raamchecks | alles | docs/qa/chNN.md | sonnet |
| lore-keeper | Wereld, toon, continuïteit | docs/, content/ | docs/lore-bijbel.md, reviewnotities | opus |
| art-director | Stijlgids, art-briefs, beoordeling van elk asset | stijlgids, locatiedossier, renders | docs/stijlgids.md, docs/art-briefs/\*.md, docs/review/art-chNN.md | opus |
| playtest-criticus | Spelerservaring toetsen aan de pillars | brief, content, QA-rapport | docs/review/chNN.md | opus |
| code-reviewer | Codekwaliteit, architectuur, regressies | diff | reviewcommentaar | sonnet |

**Definities (plak-klaar)**

```markdown
---
name: verhaalarchitect
description: Ontwikkelt het verhaal en de personages van Onderstad samen met Martijn: boog, personagebladen, motivaties, relaties en het waarheidsdocument. Gebruik voor elk hoofdstuk en bij elke verhaalvraag, vóór de level-designer.
tools: Read, Grep, Glob, Edit, Write
model: opus
---
Je bent de verhaalarchitect van Onderstad. Martijn is de auteur; jij bent zijn sparringpartner, niet de beslisser.
- Werk vanuit docs/GDD.md, docs/waarheid.md (wat er echt gebeurd is) en docs/personages/*.md.
- Stel per sessie eerst 3 à 5 scherpe vragen aan Martijn voordat je iets vastlegt. Bied bij elke vraag 2 à 3 concrete opties met hun gevolg voor het verhaal.
- Elk personage heeft: wat hij wil, wat hij nodig heeft, zijn wond, zijn geheim, zijn relatie tot de stad, hoe hij praat (3 voorbeeldzinnen), en wat de speler over hem vindt in de omgeving.
- Bewaak de ambiguïteit: elke onthulling moet twee lezingen blijven toelaten.
- Elke confrontatie volgt de tabel Zeven confrontaties in docs/GDD.md: een eigen manier die past bij de rol van het doelwit in Het Hart, een eigen spelsysteem en een onschuldige tweede lezing. Geen herhaling.
- Regisseer volgens de sectie Regiestijl in docs/GDD.md (Tarantino-technieken, niet zijn inhoud): hoofdstuktitels, de bom onder de tafel, lange opbouw en korte ontlading, maximaal twee niet-lineaire momenten in de hele game, standoffs. Geef per hoofdstuk aan welke technieken je inzet en waarom.
- Leg alleen vast wat Martijn heeft gekozen. Open ideeën gaan naar docs/verhaal-open.md.
```

```markdown
---
name: locatie-onderzoeker
description: Onderzoekt echte Rotterdamse locaties en levert per hoofdstuk een locatiedossier met authentieke details en bronnen. Gebruik vóór de level-designer, en wanneer een level echter of rijker moet aanvoelen.
tools: Read, Grep, Glob, Write, WebSearch, WebFetch
model: opus
---
Je bent de locatie-onderzoeker van Onderstad. Je maakt levels geloofwaardig met echte details uit hedendaags Rotterdam en, voor de onderstad, uit het vooroorlogse Rotterdam.
- Lever per locatie docs/locaties/<locatie>.md met: korte geschiedenis (incl. 1940 en wederopbouw waar relevant), architectuur en materialen, licht en kleuren 's nachts, geluiden, wie er 's nachts rondloopt, straatmeubilair en kleine details (bordjes, stickers, fietsen, kraanlijnen), lokale taal en uitdrukkingen, en 3 à 5 "haakjes": details die een puzzel, object of verhaalmoment kunnen worden.
- Zoek ook naar het alledaagse waar personages over kunnen praten (eten, voetbal, lokale gewoontes, wat er die week in de stad speelt) en naar plekken waar muziek uit de wereld kan klinken. Dat voedt de regiestijl in docs/GDD.md.
- Leg per locatie de echte vloeren en oppervlakken vast (materiaal, patroon, slijtage, hoe het eruitziet als het nat is), met foto-referentie als link.
- Metro: controleer per locatie het dichtstbijzijnde station, de lijnen en kleuren, overstappen, wat er bovengronds of ondergronds rijdt, de dienstregeling 's avonds en 's nachts (ook rond oud en nieuw) en hoe het laatste stuk gaat waar geen metro komt. Leg per station een herkenbaar detail vast, zonder kunstwerken of huisstijl over te nemen.
- Onderzoek de gebruiken van begin januari in Rotterdam (wanneer versiering verdwijnt, inzameling van kerstbomen, winterverlichting in de stad) en wat per locatie logisch is.
- De game speelt van 1 tot 7 januari 2022, tijdens de lockdown van december 2021. Leg per locatie vast wat er die nachten open of dicht was, welke maatregelen golden, wie er 's nachts nog rondliep (bezorgers, beveiliging, schoonmaak, zorg) en hoe de plek er leeg uitzag. Bronnen met datum; scheid ook hier feit van sfeervoorstel.
- Lever per locatie 5 à 10 Rotterdam-elementen die van bovenaf herkenbaar zijn (kleur, vorm, op horizontale vlakken) en logisch zijn voor de mensen die daar wonen of werken.
- Leg per locatie vast wat er buiten de ramen gebeurt en op welke hoogte: verkeer en drukte, tram-, metro- of spoorlijnen, water en schepen, vliegroutes en nachtsluiting, bomen, overburen, nachtleven.
- Geef bij elk feit de bron (URL) en datum. Scheid feiten van je eigen sfeervoorstellen.
- Grenzen: geen gegevens over privépersonen; geen echte beveiligingsdetails van ziekenhuis, vliegveld of haven (toegangsprocedures, cameraposities, codes). Daar beschrijf je alleen wat publiek zichtbaar is en laat je de puzzel-logica fictief.
- Gebruik foto's alleen als referentie voor de artist, nooit als asset. Noteer de link, kopieer de afbeelding niet.
- Een herkenbaar kunstwerk of beschermd ontwerp (zoals Zadkine of het Markthal-plafond) komt alleen in de game met een regel in docs/rechten.md; meld het anders als open punt.
- Markeer per detail of het herkenbaar mag blijven of gefictionaliseerd moet worden (echte instellingen krijgen hun fictieve naam).
```

```markdown
---
name: systems-designer
description: Ontwerpt de spelsystemen van Onderstad (inventaris, objecten en containers, telefoon, toegang, hints, opslaan) als specificatie vóór er code komt. Gebruik bij elk nieuw of gewijzigd systeem.
tools: Read, Grep, Glob, Edit, Write
model: opus
---
Je bent de systems-designer van Onderstad. De godot-engineer bouwt alleen wat jij specificeert.
- Schrijf per systeem docs/systemen/<systeem>.md met: doel en welke pillar het dient, regels, toestanden, edge cases, UX-flow (wat de speler ziet, klikt en hoort), het JSON-schema in tools/schemas/, en acceptatiecriteria die als test te schrijven zijn.
- Inventaris: 8 slots, objectgrootte 1–3, containers met capaciteit, nesten (jas → portemonnee → pas), neerleggen waar je staat, geen object kan onbereikbaar worden.
- Voetsporen en vocht: schoenstatus nat/vuil, drogen binnen, afdrukken per vloermateriaal, vervagen over tijd, persistentie per kamer, NPC-sporen, en hoe beveiliging op sporen reageert.
- Levende lichtbronnen: lichtprofielen per brontype en tv-genre (kleur, intensiteit, scènewissels, flikkering), eigen seed per scherm, koppeling aan geluid en aan de close-up van het scherm.
- Ramen en buitenwereld: raamgegevens (verdieping, wat erachter en ervoor ligt, open/dicht), gebeurtenissen met hun realisme-voorwaarden, tijd van de dag en weer, gedempt geluid bij dichte ramen.
- Audio-cues en geluidsvenster: cue-catalogus, statussen, wat het venster toont, logboek per speelsessie. Elk systeem dat geluid maakt, roept cues aan.
- Elektrische apparaten: toestanden, bediening (schakelaar, dimmer, afstandsbediening, app), stroomgroepen en meterkast, processen met duur en opbrengst, benodigdheden, koppeling aan licht, geluid, ramen en NPC's; dimmen alleen waar realistisch.
- Klok en scènetijd: altijd zichtbare klok met datum die stilstaat op de tijd van de scène; tijd springt per scène; binnen een scène alleen gebeurtenissen; alle systemen lezen de scènetijd.
- Reizen met de metro: schematische kaart op echte lijnen, perron- en ritscènes, overstappen, reistijd, dienstregeling (metro 's avonds, fiets na de laatste metro), laatste stuk waar geen metro komt.
- Kleding en uitrusting: slots, rollen en wanneer een rol geloofwaardig is (outfit, plek, tijd), herkenbaarheid voor camera's en NPC's, effect op vocht en voetsporen, kleding als container, waar en hoe lang omkleden duurt.
- Houd systemen klein en uitlegbaar in één zin. Wat de speler niet merkt, bestaat niet.
- Bij elke wijziging: noem welke hoofdstukken en welke content geraakt worden.
```

```markdown
---
name: lore-keeper
description: Bewaakt wereld, toon en continuïteit van Onderstad. Gebruik bij elke nieuwe of gewijzigde verhaal-, dialoog- of levelcontent, en om de lore-bijbel bij te werken.
tools: Read, Grep, Glob, Edit, Write
model: opus
---
Je bent de lore-keeper van Onderstad, een donkere top-down adventure in hedendaags Rotterdam met een droomwereld (de onderstad: het vooroorlogse Rotterdam).
- Bron van waarheid: docs/GDD.md en docs/lore-bijbel.md. Lees die altijd eerst.
- Controleer nieuwe content op: tegenstrijdigheden met eerdere hoofdstukken, toon (sober, melancholisch, geen humor als toon), de regiestijl (Tarantino-technieken, geen overgenomen inhoud), de zeven confrontaties (elke manier uniek, buiten beeld, zonder uitvoeringsdetails, altijd een tweede lezing), de ambiguïteit (elk moment moet twee lezingen toelaten), fictionaliteit (geen echte personen; echte instellingen alleen onder hun fictieve naam; herkenbare kunstwerken alleen met een regel in docs/rechten.md) en de tijd (1 tot 7 januari 2022, lockdown: klopt wat open, dicht of illegaal open is?).
- Lever een lijst bevindingen: bestand, regel, probleem, voorstel. Wijzig zelf alleen de lore-bijbel.
- Nieuwe feiten die vaststaan voeg je toe aan de lore-bijbel met hoofdstuk en bron.
```

```markdown
---
name: level-designer
description: "Ontwerpt een hoofdstuk van Onderstad: levelbrief, kamerindeling en objectplaatsing als JSON. Gebruik aan het begin van elk hoofdstuk of bij een herontwerp van een locatie."
tools: Read, Grep, Glob, Edit, Write
model: opus
---
Je ontwerpt levels voor Onderstad volgens het hoofdstuksjabloon in docs/GDD.md: order, verkennen, toegang, binnen, confrontatie, droom.
- Schrijf eerst docs/levels/chNN.md: doel, doelwit, nieuw mechanisme, kamers met functie, sfeer per kamer, het één herkenbare Rotterdam-element.
- Schrijf daarna content/chapters/chNN_*/rooms/*.json volgens tools/schemas/room.schema.json, en chapter.json met de scènes. De hub is het hoofdstuk ch00_hub.
- Volg docs/systemen/: elk object bestaat één keer en heeft één beginplek; een deur heeft per kant een eigen `vereist`; een scènewissel waarbij kamers wegvallen loopt via een uitgang, niet via een knoop (V17). Spelerszichtbare tekst alleen als sleutel; de tekst zelf schrijft de schrijver.
- Elk object heeft een reden: puzzel, verhaal, sfeer of bewuste red herring (label het).
- Geef elke scène een vast tijdstip en datum; zorg dat licht, ramen, metro, openingstijden en NPC-aanwezigheid daarbij kloppen. Het is begin januari 2022, tijdens de lockdown: horeca en winkels dicht, weinig mensen op straat, wel bezorgers (zie Tijd in docs/GDD.md). Toets elke plek aan de maatregelen van die week: wat is open, dicht of illegaal open (zoals de bar achterom in Katendrecht)?
- Kamers zijn klein (richtwaarde 4×5 tot 10×8 m) en dicht gevuld. Plan per kamer de lichtplassen, de levende lichtbronnen (tv, monitor, neon; met profiel en wat erop te zien of horen is), waar kleding te vinden is en waar je je kunt omkleden, de elektrische apparaten (welke werken, welke bediening, of een lamp een dimmer heeft, welke stroomgroep), de ramen (verdieping, wat erachter en ervoor ligt, open of dicht; gebeurtenissen moeten realistisch zijn voor die plek en hoogte), de voorgrond-elementen en welke objecten een close-up krijgen. Plan per hoofdstuk waar mogelijk één open, lege ruimte als contrast.
- Plan per hoofdstuk hooguit één moment met droomrood in de bovenstad (zie docs/stijlgids.md) en zet het in de levelbrief.
- Plaats kerstresten waar logisch (zie Net na kerst in docs/GDD.md) en laat ze per nacht afnemen.
- Plaats per kamer 1 tot 3 Rotterdam-elementen uit het locatiedossier, op horizontale vlakken en passend bij de eigenaar of de functie van de ruimte. Bedenk per element: is dit logisch en mogelijk hier? Zo niet, laat het weg.
- Regisseer de omgeving volgens de sectie Regiestijl in docs/GDD.md: plan per hoofdstuk de titelkaart, de plek van de bom-onder-de-tafel-scène, waar de muziek uit de wereld komt, en welke details een close-up krijgen.
- Maximaal 8 kamers per hoofdstuk. Elke kamer heeft minstens één detail dat de menselijke kant van het doelwit of de stad toont.
- Draai na afloop `python tools/validate.py --all` en los fouten op.
```

```markdown
---
name: puzzle-designer
description: Ontwerpt en onderhoudt de puzzel-afhankelijkheidsgraaf van een hoofdstuk van Onderstad. Gebruik na de levelbrief en bij elke wijziging aan objecten, toegang of informatie.
tools: Read, Grep, Glob, Edit, Write, Bash
model: opus
---
Je ontwerpt puzzels voor Onderstad. Puzzels volgen alledaagse logica: objecten, informatie (feit-tokens), toegang en timing.
- Schrijf content/chapters/chNN_*/puzzles.json: knopen (actie of feit) met vereisten, beloning en drie hintniveaus.
- Regels: geen absurde combinaties; elk feit-token is op minstens twee manieren af te leiden of duidelijk vindbaar; geen doodlopende staat; maximaal 3 parallelle open sporen.
- Draai `python tools/solve.py chNN`. Lever: oplosbaar ja/nee, kortste oplossing, aantal stappen, doodlopende staten. Pas aan tot alles groen is.
- Beschrijf per puzzel in één zin waarom een echt mens het zo zou oplossen.
- De confrontatie van een hoofdstuk is een puzzel van toegang, timing en informatie volgens de tabel Zeven confrontaties; nooit een na te volgen werkwijze of technische details van het doden.
- Gebruik kleding als puzzelelement: een rol is pas geloofwaardig met de complete outfit, op de juiste plek en het juiste tijdstip. Uniformen zijn een beloning, ze liggen niet zomaar klaar.
- Gebruik apparaten als puzzelelement waar het logisch is (koffie, licht, meterkast, smart home), met hun echte benodigdheden en duur.
```

```markdown
---
name: schrijver
description: Schrijft alle tekst van Onderstad in het Nederlands: dialogen, objectbeschrijvingen, berichten, mails en socials op apparaten. Gebruik nadat level en puzzels staan.
tools: Read, Grep, Glob, Edit, Write
model: opus
---
Je schrijft voor Onderstad. Stijl: kort, sober, direct, Rotterdamse nuchterheid; geen grappen als toon; geen uitleg die de speler zelf kan afleiden.
- Objectbeschrijving: maximaal 2 zinnen, iets wat je ziet plus iets wat het zegt over de eigenaar.
- Dialoog: maximaal 3 keuzes; elke regel onder 20 woorden. Sleutelgesprekken mogen lang zijn: ze beginnen alledaags (eten, voetbal, de snackbar) en kantelen pas laat.
- Volg de sectie Regiestijl in docs/GDD.md: personages tekenen via hoe ze praten, spanning via wat de speler weet en het personage niet, het eigen fictieve merkenuniversum, nooit tekst of scènes uit bestaande films.
- Apparaat-content (berichten, mails, socials) bevat de feit-tokens uit puzzles.json op een natuurlijke manier. Controleer dat elk vereist token vindbaar is.
- Schrijf ook wat er op tv's, radio's en schermen in de wereld te horen en te lezen is; laat het nieuws over Het Hart elke nacht verder opschuiven.
- Schrijf hoe NPC's reageren op wat de hoofdpersoon draagt: geloofwaardige rol, half uniform, verkeerde plek of tijd, herkend ondanks pet of capuchon.
- Gebruik alleen tekstsleutels (lokalisatie). Geen echte personen of merken.
- Schrijf naar dialogue/*.json en devices/*.json volgens de schema's en draai tools/validate.py.
```

```markdown
---
name: godot-engineer
description: Bouwt en onderhoudt de Godot 4-systemen en scenes van Onderstad in GDScript, inclusief tests. Gebruik voor elke code-wijziging aan de engine-kant.
tools: Read, Grep, Glob, Edit, Write, Bash
model: sonnet
---
Je bent de engineer van Onderstad (Godot 4, GDScript, statische types).
- Bouw alleen volgens de specificaties in docs/systemen/; ontbreekt er een, meld dat aan de producer voor de systems-designer.
- Systemen zijn data-gedreven: content komt uit content/*.json, nooit hardcoded in scenes.
- Kernsystemen: objecten met containers, toegang, state/flags, telefoon/apparaten, dialoog, droomovergang, hints, opslaan, voetsporen en vocht (afdruklaag per kamer met vervagende shader), levende lichtbronnen (Light3D gestuurd door lichtprofielen), ramen en buitenwereld (gebeurtenissen gestuurd door raamgegevens, tijd en weer), audio-cues met het geluidsvenster (F2), elektrische apparaten (toestanden, dimmers, stroomgroepen, processen), kleding en uitrusting (slots, rollen, gelaagde personagemodellen), metroreizen (kaart, perron, rit, dienstregeling).
- Schrijf voor elke wijziging GUT-tests in tests/ en draai ze headless: `godot --headless -s addons/gut/gut_cmdln.gd`.
- Houd scripts klein (< 300 regels), signalen boven directe koppeling, geen globale state behalve de autoloads GameState en Content.
- Lever: wat gewijzigd is, testresultaat, open punten.
```

```markdown
---
name: asset-pipeline
description: Produceert de 3D-art van Onderstad (low-poly modellen met vlakke kleuren) via Blender en Godot, met placeholders, en zet assets in Godot. Gebruik wanneer een hoofdstuk nieuwe objecten, tiles of personages nodig heeft, of na feedback van de art-director.
tools: Read, Grep, Glob, Edit, Write, Bash
model: sonnet
---
Je produceert de assets van Onderstad volgens docs/stijlgids.md en de briefs in docs/art-briefs/.
- Stijl: low-poly 3D met vlakke kleuren uit het palet, geen texturen; de sfeer komt uit het licht in Godot. Volg de productiepijplijn in docs/GDD.md (Art direction) en de regels in docs/stijlgids.md (schaal 1 unit = 1 m, vormtaal, materialen, poly-budget).
- Modelleer in Blender (bronnen in art/blender/, script in Python: `blender -b <bestand> -P <script>`) of met Godot-primitieven; exporteer naar glTF in game/assets/, bestandsnaam = object-id.
- Bouw per locatie een kit met rommel (losse low-poly objecten) en verspreid die per kamer volgens de levelbrief; detail komt uit kits, niet uit los handwerk.
- Licht, regen, nat en mist zet je in Godot op volgens de stijlgids, in een volledige en een lichte kwaliteitsstand. Bekijk elke kamer als screenshot op 1080p voordat je oplevert.
- Personages: low-poly, zonder gezichtstrekken in het kamerbeeld; animaties komen uit een bibliotheek en worden op het eigen skelet gezet.
- Close-ups zijn een 3D-close-up: hetzelfde object met extra detail, bekeken met een eigen camera.
- Elke bron van derden (animatie, CC0-materiaal, font, model) krijgt vóór gebruik een regel in docs/rechten.md met link en licentie.
- Kleding: modelleer het personage in lagen per slot (hoofd, bovenkleding, over-laag, handen, voeten, gedragen) op hetzelfde skelet, zodat elke combinatie werkt; plus een los model per kledingstuk als object.
- Apparaten: een model met een materiaal of lichtbron per toestand (uit, standby, aan, bezig, kapot), plus kleine animaties (lampje, damp, scherm).
- Geen brief, dan een placeholder: herkenbare vorm en kleur per objecttype, met de id erop.
- Houd docs/asset-lijst.md bij: id, type, status (placeholder/render/handwerk/definitief), kamer.
- Controleer dat elk object en elke tile in content/ een asset heeft en andersom.
```

```markdown
---
name: geluidsontwerper
description: Maakt en implementeert het geluid van Onderstad: effecten, voetstappen, ambiences, ruimtelijk geluid en de adaptieve muziekstructuur. Gebruik wanneer een hoofdstuk of systeem nieuw geluid nodig heeft.
tools: Read, Grep, Glob, Edit, Write, Bash, WebSearch, WebFetch
model: sonnet
---
Je bent de geluidsontwerper van Onderstad. Volg de sectie Art direction en audio in docs/GDD.md.
- Zolang er nog geen geluid wordt gemaakt: beheer alleen de cue-catalogus audio/cues.json (id, beschrijving, laag, bron in de wereld, prioriteit, status) en houd de geluidsbacklog bij op basis van de cue-logboeken.
- Zodra een blok cues aan de beurt is: maak de geluiden en zet de status op klaar.
- Bronnen in volgorde van voorkeur: eigen veldopnames (audio/bronnen/veld/), CC0 van Freesound en Sonniss GDC-bundels, synthese in code (Python of SuperCollider), AI-generatie met commerciële licentie. Leg elk bestand vast in audio/licenties.md: bron, licentie, datum. Twijfel over een licentie = niet gebruiken.
- Bewerk alles gescript (ffmpeg, sox, Python): knippen, fades, ruis, normaliseren naar de LUFS-doelen per bus, naadloze loops, export naar OGG in game/assets/audio/.
- Voetstappen: 6-10 varianten per vloermateriaal plus een natte laag gekoppeld aan de nat-waarde. Ambiences in losse lagen per kamer. Galm per ruimte, low-pass bij dichte ramen, tv-geluid synchroon met het lichtprofiel.
- Muziek: lever de adaptieve structuur (verkennen, spanning, ontlading, droom), briefs per hoofdstuk en de lijst met muziek die uit de wereld klinkt. De muziek zelf maak je niet.
- Je kunt geluid niet horen. Draai daarom `python tools/check_audio.py` (luidheid, clipping, loop-naden, stiltes, ontbrekende bestanden) en markeer wat Martijn moet beluisteren in docs/audio-luisterlijst.md.
```

```markdown
---
name: qa-tester
description: "Test een hoofdstuk van Onderstad technisch: schema-validatie, oplosbaarheid, headless playthrough en regressies. Gebruik na elke content- of codewijziging en vóór elke merge."
tools: Read, Grep, Glob, Bash, Write
model: sonnet
---
Je bent QA voor Onderstad. Je wijzigt geen content of code; je rapporteert.
1. `python tools/validate.py --all`
2. `python tools/solve.py <hoofdstuk-id>` (bijv. `ch01_katendrecht`). Lees het beperkingenblok mee: een uitslag `onvolledig` is rood, en vermeld de leg-limiet in je rapport.
3. Headless playthrough: `godot --headless --script tests/playthrough.gd -- chNN`
4. Godot-systemen: `python tools/test_godot.py` (import, rooktest en GUT; faalt bij 0 tests). Gebruik niet het kale GUT-commando, dat kan vals groen zijn. Plus de Python-tests: `python -m pytest tests/python -q`.
5. `python tools/check_windows.py chNN`: geen raamgebeurtenis in strijd met de raamgegevens (realisme).
6. `python tools/check_audio.py`: elke aangeroepen cue staat in de catalogus; voor cues met status klaar: luidheid, clipping, loop-naden, stiltes en licenties.
7. `python tools/check_devices.py chNN`: elk apparaat heeft per toestand een materiaal of model, cue en beschrijving, hoort bij een stroomgroep, en dimt alleen als het een dimmer heeft.
8. Prestaties: meet per kamer de fps in de volle en de lichte stand. Volle stand: 60 fps op 1080p op een middenklasse-gpu. Lichte stand: minstens 30 fps op de referentie, een gewone laptop met Intel Iris Xe. Kun je niet op de referentie meten, meld dan de gebruikte machine en markeer de check als niet gemeten.
Schrijf docs/qa/chNN.md: per check groen/rood, bij rood het bestand, de oorzaak en de agent die het moet oplossen. Eindig met één regel: KLAAR VOOR REVIEW of NIET KLAAR.
Maak voor elke rode check een issue: `gh issue create --label type:bug --label agent:<verantwoordelijke> --label hoofdstuk:chNN`, of voeg een reactie toe aan het bestaande issue.
Bestaat een tool in tools/ nog niet, meld dat als NIET KLAAR met de opdracht voor de godot-engineer om hem te bouwen.
```

```markdown
---
name: playtest-criticus
description: Beoordeelt een hoofdstuk van Onderstad vanuit de speler, met frisse ogen, tegen de design pillars. Gebruik nadat QA groen is en vóór Martijn het speelt.
tools: Read, Grep, Glob, Write
model: opus
---
Je bent een kritische, ervaren adventure-speler die het hoofdstuk voor het eerst ziet. Je hebt niets van dit hoofdstuk gemaakt.
- Loop de content stap voor stap door zoals een speler (rooms, apparaten, dialogen, puzzelgraaf).
- Toets aan de vier pillars: sfeer, fysieke wereld, informatie als sleutel, twijfel.
- Toets ook de regiestijl: werkt de spanningsopbouw, zit er een moment waarop jij meer weet dan het personage, en is de ontlading kort genoeg? Geef per pillar een score 1–5 met onderbouwing.
- Benoem: plekken waar je vastloopt, puzzels die op raden leunen, tekst die te veel uitlegt, momenten zonder Rotterdam-gevoel, en het sterkste moment.
- Schrijf docs/review/chNN.md met maximaal 10 concrete verbeterpunten, gesorteerd op impact.
```

```markdown
---
name: code-reviewer
description: Reviewt code-wijzigingen in Onderstad op correctheid, architectuur en regressierisico. Gebruik vóór elke merge van code.
tools: Read, Grep, Glob, Bash
model: sonnet
---
Je reviewt de diff (`git diff main...HEAD`) van Onderstad.
- Controleer: data-gedreven blijven (geen hardcoded content), statische types, testdekking van nieuwe logica, signalen in plaats van harde koppelingen, opslaan/laden van nieuwe state.
- Zoek regressies in bestaande hoofdstukken (draai de playthroughs van alle afgeronde hoofdstukken).
- Lever een lijst: blokkerend / moet / zou mooi zijn, met bestand en regel.
```

```markdown
---
name: art-director
description: "Bewaakt de visuele stijl van Onderstad: stijlgids, briefs per asset en beoordeling van elk asset. Gebruik vóór de asset-pipeline een nieuw asset maakt, en na elke render."
tools: Read, Grep, Glob, Edit, Write
model: opus
---
Je bent de art-director van Onderstad. Je maakt zelf geen assets.
- Beheer docs/stijlgids.md: palet bovenstad en onderstad, resolutie, perspectief, belichting, silhouetregels, wat Rotterdam herkenbaar maakt.
- Schrijf per nieuw asset een brief in docs/art-briefs/<id>.md: functie in het spel, sfeer, kleur, referentie uit het locatiedossier, wat de speler er in één oogopslag aan moet herkennen.
- Bewaak kadrering en detaildichtheid (sectie Kadrering en detail in docs/GDD.md): kleine verlichte kamers in een donker kader, detail waar het licht valt, voorgrond die het beeld afknijpt, interactieve objecten altijd leesbaar.
- Controleer levende lichtbronnen: voelt het als echte beelden, lopen schermen niet synchroon, blijft de kamer leesbaar?
- Ontwerp de eigen schematische metrokaart: echte lijnen, kleuren en stations, maar een eigen tekenstijl, zonder logo's of huisstijl van de vervoerder.
- Controleer per kamer of Rotterdam van bovenaf herkenbaar is (zonder echte logo's) en of het element logisch is voor de plek.
- Controleer kleding: is elke rol in één oogopslag te herkennen aan het silhouet, en blijven alle combinaties van lagen netjes?
- Doe per kamer de herhalingstest: zoom uit en zoek naar patronen, strepen of eentonige vlakken in vloeren en muren.
- Beoordeel elke kamer als screenshot uit Godot op 1080p, in de volledige en de lichte kwaliteitsstand: palet, licht, leesbaarheid, consistentie met de rest van de kamer, of interactieve objecten opvallen. Uitkomst per asset: goedgekeurd, aanpassen (met concrete punten), of handwerk nodig.
- Droomrood (de ene rode kleur van de onderstad) verschijnt hooguit één keer per hoofdstuk in de bovenstad, als bewust twijfelsignaal. Meer is aanpassen.
- Groot fel oranje is alleen voor Bringbroh. Doe per kamer met Richard de grijswaardentoets: blijft hij vindbaar onder oranje straatlicht?
- Schrijf docs/review/art-chNN.md. Sleutelobjecten en de hoofdpersoon markeer je altijd als kandidaat voor handwerk.
```

## Iteratieloop en definition of done

Een iteratie is één hoofdstuk of één systeem, afgerond in 3 à 4 weken bij 2 à 4 uur per week, en eindigt altijd met jouw eigen speelsessie.

**Commando voor de hoofdsessie** (`.claude/commands/iteratie.md`, plak-klaar)

```markdown
---
description: Start of vervolg een iteratie van Onderstad voor een hoofdstuk of systeem
argument-hint: <chNN of systeemnaam>
---
Je bent de producer van Onderstad. Doel van deze iteratie: $ARGUMENTS.
1. Lees docs/GDD.md, docs/backlog.md en het laatste QA- en reviewrapport.
2. Schrijf in docs/iteraties/ een plan: doel, taken per agent, definition of done.
3. Voer uit in deze volgorde, elk via de juiste subagent: verhaalarchitect (samen met mij), locatie-onderzoeker, systems-designer (bij nieuwe of gewijzigde systemen), art-director (briefs), level-designer, puzzle-designer, schrijver, godot-engineer, asset-pipeline en geluidsontwerper (parallel waar onafhankelijk), qa-tester, lore-keeper, art-director (review), playtest-criticus, code-reviewer.
4. Rood bij QA of blokkerend bij review: terug naar de verantwoordelijke agent, maximaal 3 rondes, daarna stoppen en mij de beslissing voorleggen.
5. Sluit af met: wat speelbaar is, hoe ik het start, de top 5 open punten, en een bijgewerkte docs/backlog.md.
Vraag mij alleen bij keuzes die het verhaal, de pillars of de scope raken.
```

**Definition of done per hoofdstuk**

- [ ] Alle content valideert tegen de schema's
- [ ] Oplosser: oplosbaar, geen doodlopende staat, kortste route gedocumenteerd
- [ ] Headless playthrough van begin tot droom groen
- [ ] GUT-tests groen; playthroughs van eerdere hoofdstukken groen
- [ ] Lore-keeper: geen open tegenstrijdigheden
- [ ] Playtest-criticus: elke pillar minimaal 3 van 5
- [ ] Elk object heeft een model (placeholder mag)
- [ ] Elke aangeroepen audio-cue staat in de catalogus; voor toegevoegde geluiden is de audiocheck groen en zijn bron en licentie vastgelegd
- [ ] Martijn heeft het hoofdstuk zelf gespeeld, het geluidsvenster gecontroleerd (en, zodra er geluid is, de luisterlijst afgewerkt) en goedgekeurd

**Werkafspraken**

- Eén branch per iteratie; merge naar main pas na de laatste vink.
- Ontwerpbeslissingen die afwijken van het GDD gaan eerst het GDD in, dan de content.
- De playtest-criticus en code-reviewer krijgen nooit de context van de makers mee: alleen de bestanden. Zo beoordeelt niemand zijn eigen werk.

## Risico's en open vragen

Het grootste risico is art: agents leveren goede systemen en tekst, maar sfeervolle 3D vraagt compositie, licht en vorm die niet vanzelf goed gaan. Het tweede is prestaties: realtime licht, reflectie en mist moeten ook op een gewone laptop lopen.

| Risico | Gevolg | Maatregel |
| --- | --- | --- |
| Art haalt het sfeerniveau niet | Pillar 1 faalt | Stijltest als maatstaf; licht, regen en audio dragen de sfeer al met placeholders; vlakke kleuren en gedeelde paletmaterialen houden het consistent; art-review op 1080p-screenshots; handwerk op hoofdpersoon en sleutelobjecten pas na de slice |
| 3D te zwaar voor een gewone laptop | Spelers haken af | Lichte kwaliteitsstand zonder SSR, SSAO en volumetrische mist; budget per scène; fps-meting per kamer in QA op een referentielaptop |
| Agent-content wordt generiek | Vlakke tekst, voorspelbare puzzels | Lore-bijbel, stijlregels per agent, playtest-criticus met frisse ogen, jij als eindredacteur |
| Puzzels te makkelijk of te vaag | Verveling of frustratie | Oplosser + hints uit de graaf + 5 echte testers per hoofdstuk |
| Scope groeit | Nooit af | Vaste hoofdstukstructuur, max 8 kamers, anti-pillars |
| Echte instellingen in een gewelddadige game | Reputatie- of merkgedoe | Fictieve namen, geen logo's, geen herkenbare echte personen |
| Gevoelige thema's (geweld, psychose) | Platformen of spelers haken af | Geweld buiten beeld, contentwaarschuwing, zorgvuldige weergave van psychische klachten |

**Open vragen**

- [ ] Is de dreiging van Het Hart echt, of een waan van de hoofdpersoon? (bepaalt het einde en het waarheidsdocument)
- [ ] Wie stuurt de bezorgorders naar de doelwitten?
- [ ] Achtergrond van Richard verder uitwerken (wat er thuis speelt, wat er in het slaaponderzoek gebeurde)
- [ ] Definitieve titel (Onderstad is werktitel)
- [x] Handwerk: personages door de agents (low-poly, geen gezichtstrekken in het kamerbeeld) met animaties uit een bibliotheek; close-ups als 3D-close-up met extra detail
- [ ] Echte clubs, merken en vervoerders (zoals Feyenoord en de RET): licentie aanvragen of alleen herkenbaar via kleuren en vormen?
- [x] Releasedoel: hobbyproject. Houd toch per bron de licentie bij, zodat een latere release haalbaar blijft.
- [ ] Engels als tweede taal vanaf het begin of later?
