# Consignes de travail

Pointage, app iPhone native de pointage des heures de travail. Ce fichier ne
contient que ce qui ne se déduit pas du code. Le reste est ailleurs :

- [`SPECS.md`](SPECS.md) — ce que l'on construit et **pourquoi**, les règles métier, les décisions prises
- [`AVANCEMENT.md`](AVANCEMENT.md) — **où on en est**, le plan de chaque étape et les décisions de mise en œuvre
- [`README.md`](README.md) — structure du dépôt, compilation, livraison

## La référence, avant tout le reste

**Le calcul de la CLI fait foi**, pas une interface existante. La référence est
la branche `main` du projet voisin `../timetracker` (`ymauray/timetracker`) :
`TimeCalculator.cs`, `ConfigParser.cs`, `ReleveParser.cs`, résumés dans son
`AGENTS.md`. L'app ne partage pas de code avec elle, seulement les fixtures.

Une règle métier ne naît jamais ici. Elle est d'abord livrée dans la CLI avec
sa fixture, puis la fixture est recopiée dans `Tests/Fixtures/`, à l'identique.
Ne jamais modifier une fixture de ce dépôt à la main : la CI compare le dossier
avec celui de la CLI et échoue à la moindre différence.

`Sources/Domain/` contient le calcul et ne dépend ni de SwiftUI ni de GRDB.

## Compiler

`project.yml` est la source de vérité. **Après toute modification, relancer
`xcodegen generate`** — le `.xcodeproj` est committé malgré sa génération, pour
qu'Xcode Cloud trouve le projet et son schéma.

**Régénérer juste avant de commiter, Xcode fermé.** Xcode réenregistre le
projet ouvert à sa façon, et le premier commit est parti avec cette version
réécrite au lieu de la sortie d'XcodeGen.

```sh
xcodebuild -project Pointage.xcodeproj -scheme Pointage \
  -destination 'platform=iOS Simulator,name=iPhone 16 (référence)' test
```

**Zéro avertissement.** Filtrer la sortie sur `warning:` autant que sur
`error:` : sur nannyplus, deux avertissements de concurrence ont atteint la CI
pour avoir été cherchés sur le seul `error:`.

## Vérifier un écran

**Aucun écran n'est terminé sans avoir été vu sur simulateur iPhone.** Le
simulateur de travail est « iPhone 16 (référence) », aligné sur l'appareil de
Yannick, avec `xcrun simctl ui <appareil> content_size medium`.

Depuis Xcode 27, le simulateur s'appelle DeviceHub, et System Events n'y voit
aucune fenêtre : un script ne peut pas y cliquer. Les gestes se vérifient donc
par les tests d'interface (`UITests/`), qui lancent l'app avec
`-tests-interface` : base vide en mémoire, lundi 5 octobre 2026 à 8h00, horloge
arrêtée.

## Git

Six règles, sans exception : jamais de commit ni de push sans y être invité, ne
pas les suggérer non plus, s'identifier comme co-auteur, messages en français au
format *conventional commits*.

`main` est protégée, administrateur compris : les deux vérifications de la CI
doivent passer. Le travail passe par une branche puis une *pull request*,
fusionnée en squash, seul mode autorisé.

**Xcode Cloud surveille `pre-release`, pas `main`.** Tout ce qui arrive sur
`pre-release` part sur TestFlight : n'y pousser que sur demande explicite.

## Données

L'app enregistre les heures réelles de Yannick. Aucune donnée réelle n'entre
dans l'historique : ni base SQLite, ni `releve.md` exporté, ni plist de
préférences. Les fixtures sont fictives. Vérifier avant de committer.
