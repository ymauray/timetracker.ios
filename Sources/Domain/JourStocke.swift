/// Une journée telle que l'app la stocke : de zéro à quatre heures pointées,
/// strictement croissantes, ou un code d'absence. Le bouton Pointer et la
/// saisie manuelle écrivent tous deux ici ; le nombre d'heures en donne la
/// lecture (voir « Le bouton Pointer » dans `SPECS.md`).
struct JourStocke: Equatable, Sendable {
    let date: DateCivile
    private(set) var heures: [Int]
    private(set) var absence: Absence?

    init(date: DateCivile, heures: [Int] = [], absence: Absence? = nil) {
        self.date = date
        self.heures = heures
        self.absence = absence
    }

    enum Etat: Equatable, Sendable {
        case vide
        /// Une ou trois heures : la journée n'a pas de départ.
        case enCours
        case complete(Journee)
    }

    var etat: Etat {
        if let absence { return .complete(Journee(date: date, contenu: .absence(absence))) }
        switch heures.count {
        case 0:
            return .vide
        case 2:
            return .complete(Journee(date: date, contenu: .travail(arrivee: heures[0], pause: nil, depart: heures[1])))
        case 4:
            return .complete(Journee(date: date, contenu: .travail(arrivee: heures[0], pause: heures[1]...heures[2], depart: heures[3])))
        default:
            return .enCours
        }
    }

    /// Nom de chaque heure selon leur nombre : la deuxième est un départ tant
    /// qu'aucune troisième ne la change en début de pause.
    var nomsDesHeures: [String] {
        switch heures.count {
        case 1: ["Arrivée"]
        case 2: ["Arrivée", "Départ"]
        case 3: ["Arrivée", "Début pause", "Fin pause"]
        case 4: ["Arrivée", "Début pause", "Fin pause", "Départ"]
        default: []
        }
    }

    // MARK: Bouton Pointer

    /// Ce que fera le prochain appui, nil quand plus aucun n'est possible.
    var actionSuivante: String? {
        guard absence == nil else { return nil }
        switch heures.count {
        case 0: return "Arrivée"
        case 1: return "Pause ou départ"
        case 2: return "Fin de pause"
        case 3: return "Départ"
        default: return nil
        }
    }

    enum RefusPointage: Error, Equatable, Sendable {
        case absence
        case journeeComplete
        case memeMinute

        var message: String {
            switch self {
            case .absence: "Cette journée est marquée en absence."
            case .journeeComplete: "La journée a déjà ses quatre pointages."
            case .memeMinute: "Un pointage existe déjà à cette minute ou plus tard."
            }
        }
    }

    /// Ajoute l'heure `minute`. Refusé après quatre pointages, sur un jour
    /// d'absence, et dans la même minute que le précédent ou avant lui : les
    /// heures d'une journée restent strictement croissantes.
    mutating func pointer(a minute: Int) throws(RefusPointage) {
        guard absence == nil else { throw .absence }
        guard heures.count < 4 else { throw .journeeComplete }
        if let derniere = heures.last, minute <= derniere { throw .memeMinute }
        heures.append(minute)
    }

    /// Retire le pointage le plus récent ; sans effet s'il n'y en a aucun.
    mutating func annulerDernierPointage() {
        if !heures.isEmpty { heures.removeLast() }
    }

    // MARK: Réalisé en cours

    /// Temps travaillé jusqu'à `maintenant` pour une journée en cours, pauses
    /// réelles retirées ; la pause minimum ne s'applique qu'au départ. Pour une
    /// journée complète, le réalisé du calcul.
    func realise(a maintenant: Int, reglages: Reglages) -> Int {
        switch etat {
        case .vide:
            return 0
        case .enCours:
            let fin = max(maintenant, heures.last!)
            return heures.count == 1 ? fin - heures[0] : (heures[1] - heures[0]) + (fin - heures[2])
        case let .complete(journee):
            return Calculateur.calculerJour(date: date, journee: journee, reglages: reglages).realise
        }
    }
}
