/// Les règles de cohérence d'une journée, reprises de `ReleveParser` de la CLI.
/// Le parser et l'écran d'édition passent tous deux par ici ; chacun formule
/// l'erreur à sa façon.
enum ValidationJournee {
    enum Erreur: Error, Equatable, Sendable {
        case horairesSurAbsence
        case arriveeEtDepartObligatoires
        case departAvantArrivee(depart: Int, arrivee: Int)
        case pauseIncomplete
        case finPauseAvantDebut(fin: Int, debut: Int)
        case pauseHorsJournee

        /// Le message de la CLI, au caractère près, absence d'accents comprise.
        var messageReleve: String {
            switch self {
            case .horairesSurAbsence:
                "Jour marque en absence mais des horaires sont renseignes : videz les colonnes horaires ou retirez le code absence."
            case .arriveeEtDepartObligatoires:
                "Arrivee et Depart sont obligatoires pour un jour travaille (ou renseignez un code Absence)."
            case let .departAvantArrivee(depart, arrivee):
                "Depart (\(Formats.heureMessage(depart))) doit etre apres Arrivee (\(Formats.heureMessage(arrivee)))."
            case .pauseIncomplete:
                "Debut pause et Fin pause doivent etre soit tous les deux renseignes, soit tous les deux vides."
            case let .finPauseAvantDebut(fin, debut):
                "Fin pause (\(Formats.heureMessage(fin))) doit etre apres Debut pause (\(Formats.heureMessage(debut)))."
            case .pauseHorsJournee:
                "La pause doit etre comprise entre l'arrivee et le depart."
            }
        }

        /// Le message de l'écran d'édition.
        var messageEcran: String {
            switch self {
            case .horairesSurAbsence:
                "Une journée d'absence ne peut pas avoir d'horaires."
            case .arriveeEtDepartObligatoires:
                "Renseignez l'arrivée et le départ, ou choisissez une absence."
            case .departAvantArrivee:
                "Le départ doit suivre l'arrivée."
            case .pauseIncomplete:
                "Renseignez le début et la fin de la pause, ou aucun des deux."
            case .finPauseAvantDebut:
                "La fin de la pause doit suivre son début."
            case .pauseHorsJournee:
                "La pause doit se situer entre l'arrivée et le départ."
            }
        }
    }

    /// Heures en minutes depuis minuit. Renvoie le contenu de la journée, ou la
    /// première règle enfreinte, dans l'ordre de la CLI.
    static func valider(
        arrivee: Int?, debutPause: Int?, finPause: Int?, depart: Int?, absence: Absence?
    ) -> Result<Journee.Contenu, Erreur> {
        if let absence {
            guard arrivee == nil, debutPause == nil, finPause == nil, depart == nil else {
                return .failure(.horairesSurAbsence)
            }
            return .success(.absence(absence))
        }
        guard let arrivee, let depart else { return .failure(.arriveeEtDepartObligatoires) }
        guard depart > arrivee else { return .failure(.departAvantArrivee(depart: depart, arrivee: arrivee)) }
        switch (debutPause, finPause) {
        case (nil, nil):
            return .success(.travail(arrivee: arrivee, pause: nil, depart: depart))
        case let (debut?, fin?):
            guard fin > debut else { return .failure(.finPauseAvantDebut(fin: fin, debut: debut)) }
            guard debut >= arrivee, fin <= depart else { return .failure(.pauseHorsJournee) }
            return .success(.travail(arrivee: arrivee, pause: debut...fin, depart: depart))
        default:
            return .failure(.pauseIncomplete)
        }
    }
}
