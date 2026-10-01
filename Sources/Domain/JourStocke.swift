/// Une journée telle que l'app la stocke : de zéro à quatre heures pointées,
/// strictement croissantes, et un code d'absence facultatif. Le bouton Pointer
/// et la saisie manuelle écrivent tous deux ici ; le nombre d'heures en donne la
/// lecture (voir « Le bouton Pointer » dans `SPECS.md`). Des heures et un code
/// ensemble font une demi-journée (`Demi`) ou une maladie en cours de journée.
struct JourStocke: Equatable, Sendable {
    let date: DateCivile
    private(set) var heures: [Int]
    private(set) var absence: Absence?

    init(date: DateCivile, heures: [Int] = [], absence: Absence? = nil) {
        self.date = date
        self.heures = heures
        self.absence = absence
    }

    /// Une journée saisie à la main, rangée comme si elle avait été pointée.
    init(_ journee: Journee) {
        switch journee.contenu {
        case let .travail(arrivee, pause, depart, absence):
            let heuresPause = pause.map { [$0.lowerBound, $0.upperBound] } ?? []
            self.init(date: journee.date, heures: [arrivee] + heuresPause + [depart], absence: absence)
        case let .absence(absence):
            self.init(date: journee.date, absence: absence)
        }
    }

    enum Etat: Equatable, Sendable {
        case vide
        /// Une ou trois heures : la journée n'a pas de départ. Une demi-journée
        /// sans aucune heure attend aussi les siennes.
        case enCours
        case complete(Journee)
    }

    var etat: Etat {
        switch heures.count {
        case 0:
            guard let absence else { return .vide }
            return absence == .demi ? .enCours : .complete(Journee(date: date, contenu: .absence(absence)))
        case 2:
            return .complete(Journee(date: date, contenu: .travail(
                arrivee: heures[0], pause: nil, depart: heures[1], absence: absence
            )))
        case 4:
            return .complete(Journee(date: date, contenu: .travail(
                arrivee: heures[0], pause: heures[1]...heures[2], depart: heures[3], absence: absence
            )))
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
        if let absence, !absence.porteDesHeures { return nil }
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
    /// d'absence entière (`Demi` et `Maladie` acceptent des heures), et dans la
    /// même minute que le précédent ou avant lui : les heures d'une journée
    /// restent strictement croissantes.
    mutating func pointer(a minute: Int) throws(RefusPointage) {
        if let absence, !absence.porteDesHeures { throw .absence }
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
    /// réelles retirées ; la pause minimum ne s'applique qu'au départ, et une
    /// demi-journée compte déjà sa moitié d'absence. Pour une journée complète,
    /// le réalisé du calcul.
    func realise(a maintenant: Int, reglages: Reglages) -> Int {
        switch etat {
        case .vide:
            return 0
        case .enCours:
            let demi = absence == .demi && date.estOuvre ? reglages.dureeJournee / 2 : 0
            guard let derniere = heures.last else { return demi }
            let fin = max(maintenant, derniere)
            let travail = heures.count == 1 ? fin - heures[0] : (heures[1] - heures[0]) + (fin - heures[2])
            return travail + demi
        case let .complete(journee):
            return Calculateur.calculerJour(date: date, journee: journee, reglages: reglages).realise
        }
    }
}
