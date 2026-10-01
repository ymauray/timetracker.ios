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

**5. Historique** — onglets Pointer et Historique ; jours par semaine ISO avec
leur écart, journées sans départ et jours ouvrés vides mis en évidence ; feuille
d'édition (heures ou absence), ajout d'une journée oubliée, suppression. Écrans
vérifiés en clair et en sombre.

**6. Réglages** — onglet Réglages : les quatre durées (jusqu'à 99h59), avec
l'avertissement du recalcul ; export de `releve.md` par le partage iOS, bloqué
tant qu'une journée passée n'a pas de départ ; import avec les erreurs de la CLI
ligne par ligne, puis confirmation. L'export de chaque fixture a été relu par la
CLI, soldes identiques.

## À faire

### 7. Plus tard

Widget, raccourci Siri, bouton Action. SQLite les laisse écrire en même temps
que l'app.

## Décisions

- **Aujourd'hui** : jamais compté dans les soldes, qui se lisent « au soir
  d'hier », même une fois la journée complète ; il s'affiche dans le réalisé du
  jour. Sans cela, deux pointages à midi se lisaient comme un départ et le solde
  plongeait jusqu'à la reprise.
- **Demi-journée et maladie en cours de journée** (livrées d'abord dans la CLI) :
  `Demi` + heures = travail + moitié du théorique ; `Maladie` + heures = travail
  complété jusqu'au théorique. Le bouton Pointer accepte de pointer sur ces deux
  codes ; dans l'édition, « Absence partielle » les ajoute aux heures.
- **Journée passée restée incomplète** : exclue du calcul et signalée.
- **Export avec une journée incomplète** : bloqué tant qu'elle existe, en la
  montrant ; `releve.md` ne sait pas l'écrire.
- **Import** : remplace tout l'historique et les réglages (ceux du
  front-matter), après confirmation.
- **Période des soldes** : elle court jusqu'à hier, pas seulement jusqu'au
  dernier jour complet. Une veille restée incomplète compte donc déjà en déficit,
  alors que la CLI arrête le calcul au dernier jour renseigné.
- **Messages de validation** : une seule validation (`ValidationJournee`), qui
  rend une erreur typée ; le parser la formule comme la CLI, sans accents,
  l'écran d'édition en français courant.
- **Édition d'une journée en cours** : elle ne s'enregistre qu'avec arrivée et
  départ, comme dans `releve.md` ; avant, c'est le bouton Pointer qui la mène.
- **Sélecteurs de minutes** : de 5 en 5, dans l'édition comme dans les
  réglages. Une valeur hors pas (pointée au bouton, importée, ou les 8h12 par
  défaut) reste affichée sans être arrondie. Le bouton Pointer garde la minute
  exacte.
- **Journée terminée** : le bouton reste actif et un appui affiche le refus,
  comme un cinquième pointage.
- **Appui accidentel** : un bouton « Annuler le dernier pointage » sur l'écran
  Pointer retire le pointage le plus récent du jour.
- **Deux appuis dans la même minute** : le second est refusé avec un message
  court. Les heures d'une journée restent ainsi strictement croissantes.
- **Jours fériés et congés** : saisis à la main, comme dans la CLI ; l'historique
  signale les jours ouvrés vides.
