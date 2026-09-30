/// Le calcul des soldes, repris de `TimeCalculator` de la CLI. Toutes les
/// durées sont en minutes.
enum Calculateur {
    struct Jour: Equatable, Sendable {
        let date: DateCivile
        /// Nil pour un jour ouvré non renseigné.
        let journee: Journee?
        let pauseDecomptee: Int
        let theorique: Int
        let realise: Int

        var ecart: Int { realise - theorique }
    }

    struct Semaine: Equatable, Sendable {
        let anneeIso: Int
        let semaineIso: Int
        let lundi: DateCivile
        let theorique: Int
        let realise: Int
        let ecartCumule: Int

        var ecart: Int { realise - theorique }
    }

    struct Mois: Equatable, Sendable {
        let annee: Int
        let mois: Int
        let theorique: Int
        let realise: Int
        let soldeCumule: Int
        let horsTolerance: Bool

        var ecart: Int { realise - theorique }
    }

    struct Rapport: Equatable, Sendable {
        let jours: [Jour]
        let joursNonRenseignes: [DateCivile]
        let semaines: [Semaine]
        let mois: [Mois]
    }

    /// Nil quand aucune journée n'est renseignée : sans premier jour, il n'y a
    /// pas de période à calculer. La période va du premier au dernier jour
    /// renseigné, comme dans la CLI, ou jusqu'à `jusquA` s'il est plus tard.
    static func calculer(_ journees: [Journee], reglages: Reglages, jusquA: DateCivile? = nil) -> Rapport? {
        guard let debut = journees.map(\.date).min(), let dernier = journees.map(\.date).max() else { return nil }
        let fin = max(dernier, jusquA ?? dernier)
        let parDate = Dictionary(journees.map { ($0.date, $0) }, uniquingKeysWith: { premiere, _ in premiere })

        var jours: [Jour] = []
        var joursNonRenseignes: [DateCivile] = []
        for numero in debut.numeroDeJour...fin.numeroDeJour {
            let date = DateCivile(numeroDeJour: numero)
            if let journee = parDate[date] {
                jours.append(calculerJour(date: date, journee: journee, reglages: reglages))
            } else if date.estOuvre {
                // Jour ouvré sans rien : déficit d'une journée entière. Un week-end
                // vide, lui, ne compte pas et n'est pas listé.
                joursNonRenseignes.append(date)
                jours.append(calculerJour(date: date, journee: nil, reglages: reglages))
            }
        }

        return Rapport(
            jours: jours,
            joursNonRenseignes: joursNonRenseignes,
            semaines: semaines(jours),
            mois: mois(jours, tolerance: reglages.tolerance)
        )
    }

    static func calculerJour(date: DateCivile, journee: Journee?, reglages: Reglages) -> Jour {
        let theorique = date.estOuvre ? reglages.dureeJournee : 0
        switch journee?.contenu {
        case .absence:
            return Jour(date: date, journee: journee, pauseDecomptee: 0, theorique: theorique, realise: theorique)
        case let .travail(arrivee, pause, depart):
            let pauseDecomptee = self.pauseDecomptee(arrivee: arrivee, pause: pause, depart: depart, reglages: reglages)
            return Jour(date: date, journee: journee, pauseDecomptee: pauseDecomptee, theorique: theorique,
                        realise: depart - arrivee - pauseDecomptee)
        case nil:
            return Jour(date: date, journee: nil, pauseDecomptee: 0, theorique: theorique, realise: 0)
        }
    }

    /// Règlement : une journée perd au moins la pause minimum, même sans pause
    /// saisie, sauf une journée courte (présence sous le seuil de pause), qui ne
    /// perd que sa pause réelle.
    static func pauseDecomptee(arrivee: Int, pause: ClosedRange<Int>?, depart: Int, reglages: Reglages) -> Int {
        let pauseReelle = pause.map { $0.upperBound - $0.lowerBound } ?? 0
        let presence = depart - arrivee
        return presence < reglages.seuilPause ? pauseReelle : max(pauseReelle, reglages.pauseMinimum)
    }

    private static func semaines(_ jours: [Jour]) -> [Semaine] {
        let groupes = Dictionary(grouping: jours) { $0.date.semaineIso.annee * 100 + $0.date.semaineIso.semaine }
        var cumul = 0
        return groupes.keys.sorted().map { cle in
            let groupe = groupes[cle]!
            let theorique = groupe.reduce(0) { $0 + $1.theorique }
            let realise = groupe.reduce(0) { $0 + $1.realise }
            cumul += realise - theorique
            return Semaine(anneeIso: cle / 100, semaineIso: cle % 100, lundi: groupe[0].date.lundiDeLaSemaine,
                           theorique: theorique, realise: realise, ecartCumule: cumul)
        }
    }

    private static func mois(_ jours: [Jour], tolerance: Int) -> [Mois] {
        let groupes = Dictionary(grouping: jours) { $0.date.annee * 100 + $0.date.mois }
        var cumul = 0
        return groupes.keys.sorted().map { cle in
            let groupe = groupes[cle]!
            let theorique = groupe.reduce(0) { $0 + $1.theorique }
            let realise = groupe.reduce(0) { $0 + $1.realise }
            cumul += realise - theorique
            return Mois(annee: cle / 100, mois: cle % 100, theorique: theorique, realise: realise,
                        soldeCumule: cumul, horsTolerance: abs(cumul) > tolerance)
        }
    }
}
