# TimeTracker iOS — spécifications

Document de départ du dépôt `timetracker.ios`, rédigé le 30 septembre 2026 depuis
le dépôt de la CLI. À placer à la racine du nouveau dépôt sous le nom `SPECS.md`.

## Ce que l'on construit

Une application iPhone native (Swift, SwiftUI) de pointage des heures de travail.
Un gros bouton « Pointer » enregistre l'heure courante et déduit seul s'il s'agit
d'une arrivée, d'un début de pause, d'une fin de pause ou d'un départ. Un pointage
oublié se saisit à la main. L'app applique exactement les calculs de la CLI
TimeTracker et affiche les soldes de la semaine et du mois.

**Pourquoi.** La CLI oblige à se souvenir de ses heures jusqu'à être devant
l'ordinateur. Le téléphone est là au moment où l'on arrive et où l'on part.

## La référence : la CLI voisine

Le projet CLI vit dans `../timetracker` (dépôt `ymauray/timetracker`, .NET 10).
Comme `nannyplus.ios` avec `../nannyplus`, la référence est sa branche `main`, et
non une copie. Les règles métier sont dans `TimeCalculator.cs`, `ConfigParser.cs`
et `ReleveParser.cs`, et résumées dans son `AGENTS.md`.

L'app ne partage pas de code avec la CLI. Elle partage des **fixtures** (voir plus
bas), c'est ce qui garantit que les deux calculent pareil.

## Règles métier à reproduire

Un jour, c'est quatre heures (Arrivée, Début pause, Fin pause, Départ) ou un code
d'absence. Pas de seconde pause, pas de journée à cheval sur minuit.

- Réglages : durée de la journée (8h12 par défaut), pause minimum (0h30 par
  défaut), seuil de pause (5h par défaut), tolérance mensuelle (10h par défaut).
  Ils valent pour tout l'historique : les modifier recalcule tous les soldes
  passés, comme la CLI le fait avec son front-matter unique. L'écran de réglages
  doit le dire.
- Jour travaillé : réalisé = (départ − arrivée) − pause décomptée, avec pause
  décomptée = `max(pause réelle, pause minimum)`, **y compris quand aucune pause
  n'est saisie** (règlement : une journée sans pause de midi perd 30 min).
- Journée courte : quand la présence (départ − arrivée) est **strictement
  inférieure** au seuil de pause, la pause minimum ne s'applique pas ; seule la
  pause réelle est décomptée (zéro si aucune n'est saisie). À 5h pile, la pause
  minimum s'applique.
- Codes d'absence `Conges`, `Maladie`, `Ferie`, `RTT`, `Divers` (et `CP`, alias
  historique de `Conges` à accepter à l'import) : réalisé = théorique, aucun effet
  sur le solde.
- Théorique = durée de la journée du lundi au vendredi, 0 le week-end. Un week-end
  travaillé compte donc entièrement en plus.
- Un jour ouvré sans rien entre le premier et le dernier jour renseignés compte en
  déficit d'une journée entière.
- Semaines ISO 8601 (`Calendar(identifier: .iso8601)`).
- Le solde mensuel se cumule de mois en mois sans remise à zéro. La tolérance
  s'évalue sur ce cumul.
- Validations d'une journée (reprises de `ReleveParser`) : arrivée et départ
  obligatoires ; départ après arrivée ; début et fin de pause tous deux présents ou
  tous deux absents ; fin de pause après début ; pause comprise entre arrivée et
  départ ; pas d'horaires sur un jour d'absence.

La pause minimum appliquée à un jour sans pause et la tolérance configurable
(clé `tolerance` du front-matter) sont livrées dans la CLI (commit `fea8f91`).

⚠️ Le seuil de pause est **nouveau** et doit d'abord être livré dans la CLI
(clé `seuil_pause` du front-matter, fixture couvrant 4h59, 5h00 et un seuil
modifié). Tant que ce n'est pas fait, la CLI ne sert pas de référence sur ce
point. Une CLI plus ancienne ignore les clés inconnues : elle lirait l'export
sans erreur, mais retirerait la pause minimum aux journées courtes.

## Le bouton Pointer

L'app stocke les pointages bruts du jour (heures en minutes, secondes tronquées)
et en déduit les colonnes :

| Pointages | Lecture |
| --- | --- |
| 1 | arrivée, journée en cours |
| 2 | arrivée et départ, sans pause (pause minimum décomptée si présence ≥ seuil) |
| 3 | arrivée, début et fin de pause, journée en cours |
| 4 | journée complète |

Le deuxième appui est le seul ambigu (départ ou début de pause ?) : ce modèle le
tranche sans poser de question. Le libellé du bouton annonce toujours l'action
suivante. Un cinquième appui est refusé.

Les heures sont stockées en minutes entières, jamais en `Date`, pour échapper aux
fuseaux et aux changements d'heure.

## Écrans

- **Pointer** (principal) : le bouton, les pointages du jour, le réalisé en cours,
  les soldes de la semaine et du mois, l'alerte de tolérance.
- **Historique** : liste par semaine avec l'écart de chaque jour. Édition des
  quatre heures ou d'un code d'absence, avec les validations ci-dessus. Mise en
  évidence d'une journée précédente restée incomplète (1 ou 3 pointages) et des
  jours ouvrés vides.
- **Réglages** : durée de la journée, pause minimum, seuil de pause, tolérance ;
  import et export
  de `releve.md`.

## Échange avec la CLI

L'export produit un `releve.md` que la CLI lit tel quel (front-matter avec les
quatre réglages, tableau `|Date|Arrivée|Début pause|Fin pause|Départ|Absence|`,
dates `j.m.aaaa`, heures `8h50`). L'import lit un `releve.md` existant avec les
mêmes messages d'erreur que la CLI, pour reprendre l'historique. Le PDF reste à la
CLI.

## Fixtures partagées

Les fixtures (paires `releve.md` + `attendu.json` : réalisé par jour, écart par
semaine, solde par mois, jours non renseignés) naissent dans le dépôt CLI, sous
`tests/TimeTracker.Tests/Fixtures/`, et sont vérifiées par ses tests xUnit. Ce
dépôt-ci en garde une copie dans `Tests/Fixtures/`, lue par les tests Swift.

Un job de `ios.yml` récupère `ymauray/timetracker` (dépôt public) et compare les
deux dossiers : la CI échoue si la copie a dérivé. Xcode Cloud n'a besoin que de
la copie.

## Configuration du projet, reprise de `nannyplus.ios`

Reprendre au plus près `project.yml`, `.github/workflows/ios.yml`,
`ci_scripts/ci_post_clone.sh` et `.gitignore` de `ymauray/nannyplus.ios` :

- XcodeGen : `project.yml` est la source de vérité ; le `.xcodeproj` est committé
  pour Xcode Cloud, `project.xcworkspace/` ré-inclus pour `Package.resolved`.
- `bundleIdPrefix: ch.yannickmauray`, même `DEVELOPMENT_TEAM`, iOS 26.0,
  `developmentLanguage: fr`, `SWIFT_VERSION: "6.0"`,
  `SWIFT_STRICT_CONCURRENCY: complete`, `GENERATE_INFOPLIST_FILE: YES`,
  `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO`, `MARKETING_VERSION: "1.0.0"`.
- `ci_post_clone.sh` : installe XcodeGen, reporte `$CI_BUILD_NUMBER` dans
  `CURRENT_PROJECT_VERSION`, régénère le projet.
- Xcode Cloud surveille `main` : toute fusion livre une build TestFlight.
- GitHub Actions sur toutes les branches : XcodeGen, compilation, tests sur
  simulateur, `CODE_SIGNING_ALLOWED=NO`. Plus le job de comparaison des fixtures.
- GRDB 7 pour le stockage, avec `DatabaseMigrator` (pas de base héritée à
  respecter, contrairement à nannyplus). Réglages dans `UserDefaults` via une
  classe `AppPreferences`, sans préfixe `flutter.`.
- Tests en Swift Testing, cible `bundle.unit-test` avec `TEST_HOST`.
- Structure `Sources/{App,Data,Design,Domain,Features,Preferences}`, `Resources/`,
  `Tests/`. `Domain/` contient le calcul et ne dépend ni de SwiftUI ni de GRDB.
- `AGENTS.md` sur le modèle de nannyplus : zéro avertissement, écran vérifié sur
  le simulateur « iPhone 16 (référence) », règles Git, aucune donnée réelle dans
  l'historique. Sans la contrainte de réplique 1:1 : ici la référence est le
  calcul de la CLI, pas une interface existante.

Différences avec nannyplus : iPhone seul (`TARGETED_DEVICE_FAMILY: "1"`), portrait
seul, police système.

## Étapes

1. Dans la CLI : pause minimum sur les jours sans pause, tolérance configurable,
   fixtures sous `tests/TimeTracker.Tests/Fixtures/`. Fait (`fea8f91`), sauf le
   seuil de pause, à livrer avant l'étape 3.
2. Ici : squelette XcodeGen, `ci_scripts`, `ios.yml`, `AGENTS.md`, puis un premier
   build TestFlight vide pour valider la chaîne de livraison.
3. `Domain/` en Swift, qui doit passer les fixtures copiées.
4. Pointages bruts, stockage GRDB, écran Pointer.
5. Historique et édition manuelle.
6. Réglages, import et export de `releve.md`.
7. Plus tard, si besoin : widget, raccourci Siri, bouton Action.

## Décisions

- Nom affiché : « Pointage ». Bundle ID : `ch.yannickmauray.pointage`.
- Journée courte : pas de pause minimum sous le seuil de pause, 5h par défaut,
  réglable (voir les règles métier).
- Icône : visuel provisoire proposé par Claude, remplaçable à tout moment.
