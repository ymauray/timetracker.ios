# Pointage

[![iOS CI](https://github.com/ymauray/timetracker.ios/actions/workflows/ios.yml/badge.svg?branch=main)](https://github.com/ymauray/timetracker.ios/actions/workflows/ios.yml)
[![Licence MIT](https://img.shields.io/github/license/ymauray/timetracker.ios)](LICENSE)
![iOS 26+](https://img.shields.io/badge/iOS-26%2B-14615b)

App iPhone native de pointage des heures de travail. Un bouton enregistre
l'heure courante et en déduit l'arrivée, la pause ou le départ ; l'app applique
les calculs de la CLI [TimeTracker](https://github.com/ymauray/timetracker) et
affiche les soldes de la semaine et du mois. Aucune donnée ne quitte l'appareil.

Site : [ymauray.github.io/timetracker.ios](https://ymauray.github.io/timetracker.ios/), avec la
[politique de confidentialité](https://ymauray.github.io/timetracker.ios/confidentialite.html).

- [`AGENTS.md`](AGENTS.md) — les consignes de travail, à lire en premier
- [`SPECS.md`](SPECS.md) — ce que l'on construit, les règles métier et les décisions prises
- [`AVANCEMENT.md`](AVANCEMENT.md) — où on en est, et le plan de chaque étape
- [`CONTRIBUTING.md`](CONTRIBUTING.md), [`SUPPORT.md`](SUPPORT.md), [`SECURITY.md`](SECURITY.md) — contribuer, obtenir de l'aide, signaler une faille

## Installer

L'app est en test sur TestFlight, par invitation ; elle n'est pas encore sur
l'App Store. Pour l'essayer sans invitation, la compiler depuis les sources
(voir « Construire ») et la lancer sur un simulateur ou un iPhone.

## Utiliser

- **Pointer** : un appui enregistre l'heure. Le bouton annonce l'action
  suivante (arrivée, pause ou départ, fin de pause, départ) ; « Annuler le
  dernier pointage » rattrape un appui de trop.
- **Historique** : les jours par semaine, avec l'écart de chacun. Toucher un
  jour pour corriger ses heures ou y mettre une absence ; « + » ajoute une
  journée oubliée.
- **Réglages** : durée de la journée, pause minimum, seuil de pause et
  tolérance, valables pour tout l'historique. L'export produit un `releve.md`
  que la CLI lit tel quel ; l'import reprend un `releve.md` existant et
  remplace l'historique après confirmation.

Les soldes se lisent au soir d'hier : aujourd'hui n'y entre jamais, il se lit
dans le réalisé du jour. Une demi-journée de congé ou une maladie survenue en
cours de journée se saisissent avec les heures travaillées et le motif
(« Absence partielle » dans l'édition d'une journée).

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
docs/                site GitHub Pages et politique de confidentialité
```

## Construire

Il faut Xcode (iOS 26 minimum) et XcodeGen (`brew install xcodegen`).
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

Pour livrer, amener `main` sur `pre-release` en avance rapide : Xcode Cloud
démarre le build tout seul.

Le numéro de build vient d'Xcode Cloud, pas de `project.yml` : le script de
post-clone y reporte `$CI_BUILD_NUMBER` avant de régénérer le projet.

`main` est protégée : les deux vérifications de GitHub Actions doivent passer,
administrateur compris, et les *pull requests* se fusionnent en squash. Les
dépendances (GRDB, actions GitHub) sont suivies par Dependabot. Le site
(`docs/`) est servi par GitHub Pages depuis `main`.

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
