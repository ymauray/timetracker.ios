/// L'état du formulaire d'édition d'une journée : quatre heures ou un code
/// d'absence, validés par les règles de `releve.md`.
struct EditionJour: Equatable, Sendable {
    enum Mode: Hashable, Sendable {
        case travail
        case absence
    }

    let date: DateCivile
    var mode: Mode
    var arrivee: Int?
    var debutPause: Int?
    var finPause: Int?
    var depart: Int?
    /// Le motif d'une journée d'absence entière.
    var absence: Absence
    /// En mode travail : demi-journée ou maladie survenue en cours de journée.
    var absencePartielle: Absence?

    /// Reprend une journée stockée ; une journée en cours garde ses heures, lues
    /// comme le bouton les lit (la deuxième est un départ sauf s'il y en a trois).
    init(_ jour: JourStocke) {
        date = jour.date
        if let code = jour.absence, jour.heures.isEmpty, code != .demi {
            mode = .absence
            absence = code
        } else {
            mode = .travail
            absence = .conges
            absencePartielle = jour.absence
        }
        let h = jour.heures
        switch h.count {
        case 1: arrivee = h[0]
        case 2: (arrivee, depart) = (h[0], h[1])
        case 3: (arrivee, debutPause, finPause) = (h[0], h[1], h[2])
        case 4: (arrivee, debutPause, finPause, depart) = (h[0], h[1], h[2], h[3])
        default: break
        }
    }

    var validation: Result<Journee.Contenu, ValidationJournee.Erreur> {
        switch mode {
        case .absence:
            ValidationJournee.valider(arrivee: nil, debutPause: nil, finPause: nil, depart: nil, absence: absence)
        case .travail:
            ValidationJournee.valider(
                arrivee: arrivee, debutPause: debutPause, finPause: finPause, depart: depart, absence: absencePartielle
            )
        }
    }

    /// La journée à enregistrer, nil tant que la saisie est invalide.
    var resultat: JourStocke? {
        guard case let .success(contenu) = validation else { return nil }
        return JourStocke(Journee(date: date, contenu: contenu))
    }

    var messageErreur: String? {
        guard case let .failure(erreur) = validation else { return nil }
        return erreur.messageEcran
    }
}
