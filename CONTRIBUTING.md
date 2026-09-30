# Contribuer

Merci de l'intérêt porté à Pointage ! C'est un petit projet personnel, mais les contributions externes sont bienvenues.

## Signaler un bug / proposer une fonctionnalité

Ouvrez une [issue](https://github.com/ymauray/timetracker.ios/issues/new/choose) en utilisant le modèle correspondant.

## Proposer une modification de code

1. Forkez le dépôt et créez une branche depuis `main`.
2. Installez Xcode (iOS 26 minimum) et [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).
3. Générez le projet : `xcodegen generate`. `project.yml` est la source de vérité, ne modifiez pas le `.xcodeproj` à la main.
4. Faites vos changements. Ajoutez ou mettez à jour les tests (`Tests/` pour les tests unitaires, `UITests/` pour les gestes) pour tout changement de comportement.
5. Vérifiez que tout passe localement, **sans aucun avertissement** :
   ```
   xcodebuild -project Pointage.xcodeproj -scheme Pointage \
     -destination 'platform=iOS Simulator,name=iPhone 16' test
   ```
6. Ouvrez une pull request vers `main` en décrivant le changement et son motif. Le modèle de PR vous guide.

La CI ne se déclenche que sur un push dans ce dépôt : pour une pull request venue d'un fork, le mainteneur pousse votre branche ici afin que les vérifications obligatoires tournent. Rien à faire de votre côté.

## Règles de calcul

Le calcul des soldes est celui de la CLI [TimeTracker](https://github.com/ymauray/timetracker), qui fait référence. Une règle métier ne naît pas ici : elle est d'abord livrée dans la CLI avec sa fixture, puis la fixture est recopiée dans `Tests/Fixtures/`. Ne modifiez pas une fixture de ce dépôt à la main, la CI la compare à celle de la CLI.

## Style de code

Le fichier `.editorconfig` à la racine définit les conventions de base. Le code suit Swift 6 en concurrence stricte ; les noms du domaine sont en français, comme le `releve.md` que l'app lit et écrit.

## Portée du projet

Pointage reste volontairement simple : un bouton pour pointer, un historique, les soldes, et l'échange de `releve.md` avec la CLI. Aucune donnée ne quitte l'appareil, et cela ne changera pas. N'hésitez pas à ouvrir une issue pour discuter d'une idée avant de coder quelque chose de conséquent.
