# Avancement

Où en est l'app, étape par étape, et le plan pour la suite. Les étapes sont
celles de [`SPECS.md`](SPECS.md) ; ce fichier dit comment on les réalise.

Chaque étape passe par une branche puis une *pull request*, sans avertissement,
avec ses écrans vérifiés sur « iPhone 16 (référence) ». Une version ne part sur
TestFlight que sur demande, en amenant `main` sur `pre-release`.

## Fait

**1. CLI** — pause minimum sur les jours sans pause, tolérance configurable,
fixtures partagées (`fea8f91` dans `ymauray/timetracker`).

**2. Squelette** — XcodeGen, GitHub Actions, Xcode Cloud, `AGENTS.md`, icône
provisoire. Première build livrée sur TestFlight et installée le 30 septembre
2026. Le défaut de l'assistant Xcode Cloud d'Xcode 27 et son contournement sont
dans le [`README.md`](README.md).

## À faire

### 1 bis. Seuil de pause, dans la CLI

À livrer avant l'étape 3, la CLI restant la référence du calcul.

- `ConfigParser` : clé `seuil_pause`, 5h par défaut.
- `TimeCalculator` : présence strictement inférieure au seuil → seule la pause
  réelle est décomptée.
- Fixture `journee-courte` : 4h59 sans pause, 5h00 sans pause, 4h avec 15 min
  de pause réelle, seuil modifié dans le front-matter.
- `seuilPause` ajouté au bloc `config` de chaque `attendu.json`, les trois
  fixtures existantes comprises.

La fusion dans la CLI passe d'abord, la copie ici ensuite. Entre les deux, le
job de comparaison des fixtures échoue : c'est attendu.

### 3. `Domain/` en Swift

Sans SwiftUI ni GRDB. Durées en minutes entières, dates en structure
année/mois/jour, jamais en `Date`.

- Modèles : `Reglages` (quatre durées), `Journee` (quatre heures facultatives ou
  un code d'absence ; `CP` lu comme `Conges`).
- `ReleveParser` : front-matter puis tableau, avec les messages d'erreur de la
  CLI au caractère près, absence d'accents comprise.
- `Calculateur` : jours (pause décomptée, théorique, réalisé), jours non
  renseignés, semaines ISO avec écart cumulé, mois avec solde cumulé et
  dépassement de tolérance.
- `ReleveWriter` : export, dates `j.m.aaaa`, heures `8h50`.
- Validation d'une journée : une seule fonction, partagée par le parser et
  l'écran d'édition, pour des messages identiques.
- Tests : un test paramétré par dossier de fixture, qui compare tout
  `attendu.json` ; un aller-retour lecture → écriture → lecture sur chaque
  fixture.

### 4. Pointages, stockage, écran Pointer

- GRDB revient, `Package.resolved` commité.
- Table `jour` : `date` en clé, `h1` à `h4` en minutes, `absence`. Pointages
  bruts et saisie manuelle écrivent les mêmes colonnes ; le nombre d'heures
  renseignées en donne la lecture (tableau de `SPECS.md`). Schéma créé par
  `DatabaseMigrator`.
- Horloge injectable, pour tester le bouton sans l'heure réelle.
- Écran : bouton annonçant l'action suivante (cinquième appui refusé),
  pointages du jour, réalisé en cours rafraîchi chaque minute, soldes de la
  semaine et du mois, alerte de tolérance, bouton « Annuler le dernier
  pointage ».
- Première build utilisable au quotidien.

### 5. Historique et édition

- Liste par semaine ISO, écart de chaque jour.
- Jours ouvrés vides et journées incomplètes mis en évidence.
- Feuille d'édition : quatre heures ou code d'absence, validations de l'étape 3.
- Ajout d'une journée oubliée, suppression d'une journée.

### 6. Réglages, import et export

- Quatre réglages dans `AppPreferences` (UserDefaults), avec l'avertissement
  que les modifier recalcule tout l'historique.
- Export : `releve.md` produit par `ReleveWriter`, via le partage iOS.
- Import : même parser, erreurs affichées ligne par ligne comme dans la CLI.

### 7. Plus tard

Widget, raccourci Siri, bouton Action. SQLite les laisse écrire en même temps
que l'app.

## Décisions

- **Journée en cours** (1 ou 3 pointages) : exclue des soldes, qui se lisent
  « au soir d'hier » ; le réalisé en cours s'affiche à part.
- **Journée passée restée incomplète** : exclue du calcul et signalée.
- **Export avec une journée incomplète** : bloqué tant qu'elle existe, en la
  montrant ; `releve.md` ne sait pas l'écrire.
- **Import** : remplace tout l'historique, après confirmation.
- **Appui accidentel** : un bouton « Annuler le dernier pointage » sur l'écran
  Pointer retire le pointage le plus récent du jour.
- **Deux appuis dans la même minute** : le second est refusé avec un message
  court. Les heures d'une journée restent ainsi strictement croissantes.
- **Jours fériés et congés** : saisis à la main, comme dans la CLI ; l'historique
  signale les jours ouvrés vides.
