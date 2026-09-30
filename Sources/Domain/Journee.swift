/// Les réglages du calcul, en minutes. Ils valent pour tout l'historique, comme
/// le front-matter de `releve.md` pour la CLI.
struct Reglages: Equatable, Sendable {
    var dureeJournee: Int
    var pauseMinimum: Int
    var seuilPause: Int
    var tolerance: Int

    static let defaut = Reglages(dureeJournee: 8 * 60 + 12, pauseMinimum: 30, seuilPause: 5 * 60, tolerance: 10 * 60)
}

enum Absence: String, CaseIterable, Sendable {
    case conges = "Conges"
    case maladie = "Maladie"
    case ferie = "Ferie"
    case rtt = "RTT"
    case divers = "Divers"
}

/// Une journée complète et valide : quatre heures (en minutes depuis minuit),
/// pause facultative, ou un code d'absence.
struct Journee: Equatable, Sendable {
    enum Contenu: Equatable, Sendable {
        case travail(arrivee: Int, pause: ClosedRange<Int>?, depart: Int)
        case absence(Absence)
    }

    let date: DateCivile
    let contenu: Contenu
}

/// Une erreur de lecture de `releve.md`, au format des messages de la CLI.
struct ErreurReleve: Equatable, Sendable {
    let ligne: Int
    let message: String
}
