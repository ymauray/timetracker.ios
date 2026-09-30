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

**1 bis. Seuil de pause** — clé `seuil_pause` dans la CLI, fixtures
`journee-courte` et `seuil-pause-configure` (`1c968f9` dans `ymauray/timetracker`).

**3. Domaine** — `Sources/Domain/` : `DateCivile` (dates sans fuseau, semaines
ISO par calcul), `ReleveParser` (messages de la CLI au caractère près),
`ValidationJournee`, `Calculateur`, `ReleveWriter`. Les cinq fixtures passent,
ainsi qu'un aller-retour export → relecture sur chacune.

**4. Pointer** — `JourStocke` (zéro à quatre heures ou une absence, lecture
selon leur nombre, bouton, annulation, refus), `Bilan` (soldes au soir d'hier),
table `jour` sous GRDB, horloge injectable, écran Pointer vérifié en clair et en
sombre. Première build utilisable au quotidien.

## À faire

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
- **Période des soldes** : elle court jusqu'à hier, pas seulement jusqu'au
  dernier jour complet. Une veille restée incomplète compte donc déjà en déficit,
  alors que la CLI arrête le calcul au dernier jour renseigné.
- **Journée terminée** : le bouton reste actif et un appui affiche le refus,
  comme un cinquième pointage.
- **Appui accidentel** : un bouton « Annuler le dernier pointage » sur l'écran
  Pointer retire le pointage le plus récent du jour.
- **Deux appuis dans la même minute** : le second est refusé avec un message
  court. Les heures d'une journée restent ainsi strictement croissantes.
- **Jours fériés et congés** : saisis à la main, comme dans la CLI ; l'historique
  signale les jours ouvrés vides.
