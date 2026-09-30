# Pointage

App iPhone native de pointage des heures de travail. Un bouton enregistre
l'heure courante et en déduit l'arrivée, la pause ou le départ ; l'app applique
les calculs de la CLI [TimeTracker](https://github.com/ymauray/timetracker) et
affiche les soldes de la semaine et du mois. Aucune donnée ne quitte l'appareil.

- [`AGENTS.md`](AGENTS.md) — les consignes de travail, à lire en premier
- [`SPECS.md`](SPECS.md) — ce que l'on construit, les règles métier et les décisions prises
- [`AVANCEMENT.md`](AVANCEMENT.md) — où on en est, et le plan de chaque étape

## Structure

```
project.yml          description du projet, source de vérité (XcodeGen)
Sources/
  App/               point d'entrée
  Domain/            calcul des soldes, sans SwiftUI ni GRDB
  Data/              base SQLite (GRDB)
  Features/          un dossier par écran
  Design/            couleurs, formats d'heures
  Preferences/       réglages (UserDefaults)
Resources/           icône d'app
Tests/               tests unitaires (Swift Testing)
  Fixtures/          copie des fixtures de la CLI, à ne pas modifier ici
UITests/             tests d'interface (XCTest), app lancée avec -tests-interface
ci_scripts/          Xcode Cloud
```

Les dossiers de `Sources/` apparaissent au fil des étapes de `SPECS.md`.

## Construire

`project.yml` est la source de vérité. Après toute modification, régénérer :

```sh
xcodegen generate
open Pointage.xcodeproj
```

Le `.xcodeproj` est malgré tout committé : Xcode Cloud a besoin de trouver le
projet et son schéma partagé dans le dépôt.

Tests :

```sh
xcodebuild -project Pointage.xcodeproj -scheme Pointage \
  -destination 'platform=iOS Simulator,name=iPhone 16 (référence)' test
```

## Livraison

Deux pipelines, qui ne valident pas la même chose :

- **GitHub Actions** (`.github/workflows/ios.yml`) se déclenche sur toutes les
  branches : régénération par XcodeGen, compilation, tests. Un second job compare
  `Tests/Fixtures/` avec celles de la branche `main` de la CLI.
- **Xcode Cloud** (`ci_scripts/ci_post_clone.sh`) surveille `pre-release` : il
  ajoute la résolution figée des paquets, la signature et la livraison
  TestFlight. Les fusions sur `main` ne livrent rien ; une version part sur
  TestFlight quand `main` est amenée sur `pre-release`.

Le numéro de build vient d'Xcode Cloud, pas de `project.yml` : le script de
post-clone y reporte `$CI_BUILD_NUMBER` avant de régénérer le projet.

Seule dépendance : GRDB. `Package.resolved` doit rester versionné dans
`Pointage.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/` : Xcode Cloud
désactive la résolution automatique des paquets et s'arrête sans lui, ce que
GitHub Actions ne peut pas détecter.

**Créer un processus Xcode Cloud avec Xcode 27** bute sur un défaut de
l'assistant : il exige de connecter chaque dépôt dont dépend le projet, même
public et appartenant à quelqu'un d'autre, ce qui est impossible. Le processus
existant n'est pas concerné, ses builds récupèrent les paquets publics sans
autorisation. Pour en créer un nouveau, retirer les paquets de `project.yml` le
temps de l'assistant, sans commiter, puis les remettre
([question Stack Overflow](https://stackoverflow.com/questions/80006430/unable-to-create-new-xcode-cloud-workflow-on-xcode-27)).
